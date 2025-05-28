<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class AccountCreatedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $tenTaiKhoan;
    public $matKhau;

    /**
     * Tạo một email mới với thông tin tài khoản.
     *
     * @param string $tenTaiKhoan Tên tài khoản của người dùng
     * @param string $matKhau Mật khẩu của người dùng
     */
    
     public function __construct($tenTaiKhoan, $matKhau)
    {
        $this->tenTaiKhoan = $tenTaiKhoan;
        $this->matKhau = $matKhau;
    }

    /**
     * Xây dựng nội dung email.
     *
     * @return $this
     */
    public function build()
    {
        return $this->subject('Thông tin tài khoản mới')
                    ->view('emails.account_created')
                    ->with([
                        'tenTaiKhoan' => $this->tenTaiKhoan,
                        'matKhau' => $this->matKhau,
                    ]);
    }
}
