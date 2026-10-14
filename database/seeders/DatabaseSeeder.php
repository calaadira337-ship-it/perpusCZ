<?php

namespace Database\Seeders;

use App\Models\Anggota;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed idempotent: aman dijalankan ulang tanpa duplikasi data.
     * Password akun contoh hanya di-set saat akun baru dibuat.
     */
    public function run(): void
    {
        // Admin + contoh buku
        $this->call(AdminSeeder::class);

        // ================= AKUN CONTOH ANGGOTA =================
        $budi = $this->upsertUser('budi', [
            'nama_lengkap' => 'Budi Santoso',
            'email' => 'budi@perpus.test',
            'role' => 'user',
            'status' => 'aktif',
        ], 'user123');

        Anggota::firstOrCreate(
            ['id_user' => $budi->id_user],
            [
                'nis' => '2024001',
                'nama' => 'Budi Santoso',
                'kelas' => 'XI IPA 2',
                'alamat' => 'Jl. Merdeka No. 1',
            ]
        );

        $siti = $this->upsertUser('siti', [
            'nama_lengkap' => 'Siti Aminah',
            'email' => 'siti@perpus.test',
            'role' => 'user',
            'status' => 'aktif',
        ], 'user123');

        Anggota::firstOrCreate(
            ['id_user' => $siti->id_user],
            [
                'nis' => '2024002',
                'nama' => 'Siti Aminah',
                'kelas' => 'X IPS 1',
                'alamat' => 'Jl. Sudirman No. 45',
            ]
        );
    }

    /**
     * Buat user bila belum ada; JANGAN menimpa data yang sudah ada.
     * Password hanya diberikan saat pembuatan akun baru.
     */
    private function upsertUser(string $username, array $attributes, string $password): User
    {
        $user = User::firstOrNew(['username' => $username]);

        if (! $user->exists) {
            $user->fill($attributes);
            $user->password = Hash::make($password);
        } else {
            foreach ($attributes as $key => $value) {
                if (blank($user->{$key})) {
                    $user->{$key} = $value;
                }
            }
        }

        $user->save();

        return $user;
    }
}
