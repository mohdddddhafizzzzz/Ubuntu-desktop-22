# Ubuntu Desktop di Railway

Desktop Ubuntu 22.04 (XFCE) yang bisa dibuka lewat browser, lengkap dengan Google Chrome dan akses SSH. Siap di-deploy ke [Railway](https://railway.app).

## Fitur

- Ubuntu 22.04 + XFCE4
- Akses lewat browser (noVNC), tanpa perlu install aplikasi
- Google Chrome (amd64) sudah terpasang, jalan dengan `--no-sandbox`
- Akses SSH lewat Railway TCP Proxy
- Resolusi dan password bisa diatur lewat environment variable

## Struktur

```
.
├── Dockerfile
├── start.sh
└── README.md
```

## Deploy ke Railway

1. Fork atau upload repo ini ke GitHub.
2. Di Railway, pilih **New Project → Deploy from GitHub repo**, lalu pilih repo ini.
3. Buka tab **Variables** dan isi `PASSWORD` (lihat tabel di bawah).
4. Buka **Settings → Networking**:
   - Klik **Generate Domain** untuk akses desktop lewat browser.
   - Klik **TCP Proxy**, isi port `22` untuk akses SSH.
5. Tunggu build selesai, lalu buka domain yang dibuat.

## Environment Variables

| Variable | Wajib | Default | Keterangan |
|---|---|---|---|
| `PASSWORD` | Ya | acak (tampil di log) | Satu password untuk desktop (VNC) dan login root SSH. VNC hanya membaca 8 karakter pertama |
| `SSH_PUBLIC_KEY` | Tidak | - | Public key untuk login SSH tanpa password (`~/.ssh/id_ed25519.pub`) |
| `RESOLUTION` | Tidak | `1280x720` | Resolusi desktop, contoh `1920x1080` |
| `PORT` | Tidak | `6080` | Diisi otomatis oleh Railway |

## Cara Pakai

### Desktop lewat browser

Buka domain yang digenerate Railway, klik **Connect**, lalu masukkan `PASSWORD` (8 karakter pertama).

### SSH

Setelah TCP Proxy aktif, Railway memberi alamat seperti `xxx.proxy.rlwy.net:12345`:

```bash
ssh root@xxx.proxy.rlwy.net -p 12345
```

### Chrome

Buka dari menu **Applications → Internet**, atau jalankan `google-chrome-stable` di terminal.

## Port

| Port | Fungsi | Akses |
|---|---|---|
| `$PORT` (default 6080) | noVNC (desktop di browser) | Publik lewat domain Railway |
| 22 | SSH | Publik lewat TCP Proxy |
| 5901 | VNC | Hanya di dalam container (localhost) |

## Menjalankan Lokal (opsional)

```bash
docker build -t ubuntu-desktop .
docker run -p 6080:6080 -p 2222:22 \
  -e PASSWORD=passwordkuat \
  ubuntu-desktop
```

Desktop: http://localhost:6080 — SSH: `ssh root@localhost -p 2222`

## Catatan

- **Data tidak permanen.** Semua file hilang saat redeploy. Tambahkan **Volume** di Railway dan mount ke `/root` kalau ingin menyimpan data.
- **Keamanan.** Container berjalan sebagai root dan terbuka ke internet. Pakai `PASSWORD` yang kuat. Karena VNC hanya membaca 8 karakter pertama, pastikan 8 karakter itu sudah acak. Lebih aman lagi kalau tambah `SSH_PUBLIC_KEY`.
- **Resource.** Desktop butuh RAM sekitar 1 GB atau lebih. Cek limit plan Railway kamu.
- **Line ending.** Pastikan `start.sh` memakai LF, bukan CRLF, supaya tidak error `bad interpreter`.
- **Firefox.** Versi apt di Ubuntu 22.04 adalah paket snap yang tidak jalan di container, jadi tidak disertakan.

## Troubleshooting

| Masalah | Solusi |
|---|---|
| Layar hitam / desktop tidak muncul | Cek log deploy, pastikan `start.sh` berjalan tanpa error |
| `bad interpreter` | Ubah line ending `start.sh` ke LF |
| SSH `Permission denied` | Pastikan `PASSWORD` benar, atau cek password acak di log deploy |
| Chrome crash | Naikkan RAM atau tutup tab yang tidak perlu |
