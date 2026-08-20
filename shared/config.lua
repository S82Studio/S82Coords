Config = {}

-- Lenh mo giao dien
Config.Command = 's82coords'

-- Phim tat mo/dong nhanh (FiveM keymap, doi trong Settings > Key Bindings > FiveM neu can)
Config.EnableKeybind = true
Config.DefaultKey = 'F6'

-- So chu so thap phan khi lam tron toa do
Config.Decimals = 2

-- Toc do cap nhat toa do khi UI dang mo (ms)
Config.RefreshRate = 100

-- Gioi han quyen su dung bang ACE permission
-- Neu RequireAce = false thi ai cung dung duoc lenh
-- [ add_ace group.admin s82.coords allow ]
Config.RequireAce = false
Config.AcePermission = 's82.coords'

-- Cong cu laser: mau va khoang cach toi da (met)
Config.Laser = {
    maxDistance = 50.0,
    color = { r = 40, g = 255, b = 80 }, -- xanh la neon, de nhin ngoai map
    thickness = 2,
}

-- Danh sach dia diem yeu thich mac dinh (co the de trong)
Config.DefaultFavorites = {
    -- { label = 'Peach Blossom City - Trung tam', coords = vector4(0.0, 0.0, 72.0, 0.0) },
}