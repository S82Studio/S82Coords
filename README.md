# S82 Coords

Công cụ lấy toạ độ cho **S82 Studio**.

## Tính năng

- Hiển thị toạ độ X, Y, Z và hướng (heading) theo thời gian thực
- Sao chép nhanh: `vector3()`, `vector4()`, `{x, y, z}`, `x, y, z`
- Công cụ Laser: chiếu tia ngắm từ camera, hiện toạ độ điểm chạm, sao chép luôn
- Lưu địa điểm yêu thích (đặt tên, di chuyển tới, xoá) — lưu bằng KVP nên còn sau khi restart resource
- Giao diện tiếng Việt, theme sakura đồng bộ với các resource S82 khác
- Giới hạn quyền dùng lệnh bằng ACE permission (tuỳ chỉnh trong config)

## Cài đặt

1. Copy thư mục `s82coords` vào `resources/`
2. Thêm vào `server.cfg`:

```cfg
ensure s82coords
```

3. (Tuỳ chọn) Cấp quyền ACE cho admin nếu `Config.RequireAce = true`:

```cfg
add_ace group.admin s82.coords allow
```

## Lệnh

| Lệnh | Mô tả |
|------|-------|
| `/s82coords` | Mở/đóng giao diện |
| Phím `F6` | Mở/đóng nhanh (đổi trong Cài đặt > Phím tắt > FiveM, hoặc đổi `Config.DefaultKey`) |

## Cấu hình

Tất cả tuỳ chỉnh nằm trong `shared/config.lua`: lệnh, phím tắt, số chữ số thập phân, tốc độ cập nhật, quyền ACE, màu/khoảng cách laser, danh sách yêu thích mặc định.
