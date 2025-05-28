from flask import Flask, request, jsonify
import cv2
import face_recognition
import numpy as np
import os
import pickle

app = Flask(__name__)

UPLOAD_FOLDER = 'Train'
MODEL_FILE = 'trained_model.pkl'

# Tải ảnh từ thư mục 'Train' và mã hóa khuôn mặt
def load_and_encode_images(path=UPLOAD_FOLDER, existing_classNames=[]):
    images = []
    classNames = []
    myList = os.listdir(path)

    encodeList = []
    for cl in myList:
        if os.path.splitext(cl)[0] in existing_classNames:
            continue  

        curImg = cv2.imread(f"{path}/{cl}")
        if curImg is None:
            print(f"Lỗi: Không thể đọc ảnh từ {cl}")
            continue

        img_rgb = cv2.cvtColor(curImg, cv2.COLOR_BGR2RGB)
        encodings = face_recognition.face_encodings(img_rgb)

        if len(encodings) == 0:
            print(f"Lỗi: Không tìm thấy khuôn mặt trong ảnh {cl}")
            continue

        images.append(curImg)
        classNames.append(os.path.splitext(cl)[0])
        encodeList.append(encodings[0])

    return encodeList, classNames

# Huấn luyện mô hình
def train_model(X, y):
    from sklearn.decomposition import PCA
    from sklearn.svm import SVC

    pca = PCA(n_components=min(len(X), 7))
    X_pca = pca.fit_transform(X)

    svm = SVC(kernel='linear', probability=True)
    svm.fit(X_pca, y)

    return pca, svm

# Hàm cập nhật mô hình khi có ảnh mới
def update_model():
    print("Đang kiểm tra và cập nhật mô hình...")

    # Tải mô hình hiện tại từ file
    try:
        with open(MODEL_FILE, 'rb') as f:
            pca, svm, classNames, encodeListKnow = pickle.load(f)
    except (FileNotFoundError, EOFError):
        # Nếu chưa có mô hình nào, khởi tạo mô hình mới
        pca, svm, classNames, encodeListKnow = None, None, [], []

    # Chỉ tải ảnh mới trong thư mục 'Train'
    encodeListNew, classNamesNew = load_and_encode_images(UPLOAD_FOLDER, classNames)

    # Kiểm tra nếu có ảnh mới
    if encodeListNew:
        # Thêm ảnh mới vào danh sách ảnh đã mã hóa
        encodeListKnow.extend(encodeListNew)
        classNames.extend(classNamesNew)

        # Huấn luyện lại mô hình với ảnh mới
        X = encodeListKnow
        y = list(range(len(encodeListKnow)))

        pca, svm = train_model(X, y)

        # Lưu lại mô hình cập nhật
        with open(MODEL_FILE, 'wb') as f:
            pickle.dump((pca, svm, classNames, encodeListKnow), f)

        print("Mô hình đã được cập nhật.")
    else:
        print("Không có ảnh mới để cập nhật mô hình.")

# Dự đoán trên ảnh mới
def predict_face(model, pca, image, encodeListKnow, classNames):
    framS = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    facecurFrame = face_recognition.face_locations(framS)
    encodecurFrame = face_recognition.face_encodings(framS)

    if len(facecurFrame) == 0:
        print("Không nhận diện được khuôn mặt")
        return

    for encodeFace, faceLoc in zip(encodecurFrame, facecurFrame):
        faceDis = face_recognition.face_distance(encodeListKnow, encodeFace)
        matchIndex = np.argmin(faceDis)

        if faceDis[matchIndex] < 0.50:
            name = classNames[matchIndex].upper()
            print(f"Ảnh này thuộc về nhãn: {name}")
            return name
        else:
            print("Không nhận diện được khuôn mặt")
            return None

# Tải mô hình đã huấn luyện
with open(MODEL_FILE, 'rb') as f:
    pca, svm, classNames, encodeListKnow = pickle.load(f)

# Route upload ảnh
@app.route('/upload', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        return jsonify({"error": "Không tìm thấy file ảnh."}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "Không tìm thấy tên file."}), 400

    # Lưu ảnh vào thư mục Train
    image_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(image_path)

    # Kiểm tra và mã hóa khuôn mặt trong ảnh
    curImg = cv2.imread(image_path)
    if curImg is None:
        return jsonify({"error": "Không thể đọc ảnh."}), 400

    img_rgb = cv2.cvtColor(curImg, cv2.COLOR_BGR2RGB)
    encodings = face_recognition.face_encodings(img_rgb)

    if len(encodings) == 0:
        # Nếu không tìm thấy khuôn mặt, xóa ảnh và trả về lỗi
        os.remove(image_path)
        return jsonify({"error": "Lỗi thiết lập khuôn mặt. Ảnh không chứa khuôn mặt."}), 400

    # Cập nhật mô hình mỗi khi có ảnh mới được upload
    update_model()

    return jsonify({"message": "Mô hình đã được cập nhật sau khi tải ảnh."}), 200

# Route dự đoán khuôn mặt
@app.route('/predict', methods=['POST'])
def predict_image():

    if 'file' not in request.files:
        return jsonify({"error": "Không tìm thấy file ảnh."}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "Không tìm thấy tên file."}), 400

    # Đọc ảnh từ file để dự đoán
    input_image = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
    input_image = cv2.resize(input_image, (input_image.shape[1] // 2, input_image.shape[0] // 2))
    
    if input_image is not None:
        # Tải lại mô hình từ file
        with open(MODEL_FILE, 'rb') as f:
            pca, svm, classNames, encodeListKnow = pickle.load(f)

        name = predict_face(svm, pca, input_image, encodeListKnow, classNames)
        return jsonify({"name": name}) if name else jsonify({"error": "Không nhận diện được khuôn mặt."}), 200
    else:
        return jsonify({"error": "Không thể đọc ảnh."}), 400

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
