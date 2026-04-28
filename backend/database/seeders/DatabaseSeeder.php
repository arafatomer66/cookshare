<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\Story;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Cooks — small roster around the Gulshan/Banani area so the map feels populated.
        $cooks = [
            ['demo@cookshare.app', 'Demo Cook', 'Home cook in Dhaka — Bengali traditional + fusion.', 23.7806, 90.4193],
            ['rumana@cookshare.app', 'Rumana Akter', 'Banani auntie famous for kachchi biriyani.', 23.7937, 90.4066],
            ['arif@cookshare.app', 'Arif Hossain', 'Weekend pitha + breakfast specialist.', 23.7812, 90.4242],
            ['nadia@cookshare.app', 'Nadia Rahman', 'Gulshan-2 home baker — desserts & continental.', 23.7925, 90.4150],
            ['imran@cookshare.app', 'Imran Chowdhury', 'Bachelor chef in Niketon — quick lunches.', 23.7770, 90.4135],
            ['sumi@cookshare.app', 'Sumi Khatun', 'Halda fish & traditional Chittagong dishes.', 23.7700, 90.4100],
        ];

        $whatsapps = [
            'demo@cookshare.app' => '+8801711000001',
            'rumana@cookshare.app' => '+8801711000002',
            'arif@cookshare.app' => '+8801711000003',
            'nadia@cookshare.app' => '+8801711000004',
            'imran@cookshare.app' => '+8801711000005',
            'sumi@cookshare.app' => '+8801711000006',
        ];

        $cookModels = [];
        foreach ($cooks as [$email, $name, $bio, $lat, $lng]) {
            $cookModels[$email] = User::firstOrCreate(
                ['email' => $email],
                [
                    'name' => $name,
                    'password' => 'password',
                    'bio' => $bio,
                    'default_lat' => $lat,
                    'default_lng' => $lng,
                    'whatsapp_number' => $whatsapps[$email] ?? null,
                ]
            );
            // Backfill whatsapp_number on previously seeded users.
            if (empty($cookModels[$email]->whatsapp_number)) {
                $cookModels[$email]->update(['whatsapp_number' => $whatsapps[$email] ?? null]);
            }
        }

        // Posts — clustered around Gulshan-Banani-Niketon for a dense map.
        $samples = [
            // [cook email, dish, cuisine, lat, lng, area, photo seed]
            ['demo@cookshare.app',   'Khichuri & Beef',   'Bengali',     23.7806, 90.4193, 'Banani',       1080],
            ['demo@cookshare.app',   'Egg Bhuna',         'Bengali',     23.7820, 90.4205, 'Banani',       210],
            ['rumana@cookshare.app', 'Kachchi Biriyani',  'Bengali',     23.7937, 90.4066, 'Gulshan-1',    292],
            ['rumana@cookshare.app', 'Borhani',           'Bengali',     23.7945, 90.4072, 'Gulshan-1',    301],
            ['arif@cookshare.app',   'Bhapa Pitha',       'Bengali',     23.7812, 90.4242, 'Banani DOHS',  445],
            ['arif@cookshare.app',   'Paratha & Dal',     'Bengali',     23.7800, 90.4248, 'Banani DOHS',  178],
            ['nadia@cookshare.app',  'Chocolate Brownie', 'Dessert',     23.7925, 90.4150, 'Gulshan-2',    520],
            ['nadia@cookshare.app',  'Pasta Carbonara',   'Italian',     23.7918, 90.4145, 'Gulshan-2',    312],
            ['nadia@cookshare.app',  'Cheesecake Slice',  'Dessert',     23.7930, 90.4158, 'Gulshan-2',    618],
            ['imran@cookshare.app',  'Chicken Tehari',    'Bengali',     23.7770, 90.4135, 'Niketon',      155],
            ['imran@cookshare.app',  'Beef Khichuri',     'Bengali',     23.7765, 90.4128, 'Niketon',      199],
            ['sumi@cookshare.app',   'Hilsa Curry',       'Bengali',     23.7700, 90.4100, 'Mohakhali',    488],
            ['sumi@cookshare.app',   'Shutki Bhuna',      'Chittagong',  23.7715, 90.4115, 'Mohakhali',    540],
            ['demo@cookshare.app',   'Sushi Roll',        'Japanese',    23.7790, 90.4170, 'Banani',       365],
            ['rumana@cookshare.app', 'Mutton Rezala',     'Bengali',     23.7960, 90.4080, 'Gulshan-1',    410],
        ];

        foreach ($samples as [$email, $dish, $cuisine, $lat, $lng, $area, $seed]) {
            $cook = $cookModels[$email];
            Post::firstOrCreate(
                ['user_id' => $cook->id, 'dish_name' => $dish],
                [
                    'caption' => "{$dish} from {$area}, freshly cooked.",
                    'photo_url' => "https://picsum.photos/seed/{$seed}/600/600",
                    'cuisine' => $cuisine,
                    'cooking_minutes' => rand(20, 90),
                    'lat' => $lat,
                    'lng' => $lng,
                ]
            );
        }

        // Stories — a handful of active stories so the rings strip has something to show.
        // Mix of for-sale + just-sharing so we exercise both UX paths.
        $stories = [
            // [email, dish, area, lat, lng, seed, isAvailable, portions, price]
            ['rumana@cookshare.app', 'Kachchi Biriyani — fresh batch', 'Gulshan-1', 23.7937, 90.4066, 711, true, 6, '350.00'],
            ['nadia@cookshare.app',  'Just iced this cheesecake',     'Gulshan-2', 23.7925, 90.4150, 822, true, 4, '450.00'],
            ['arif@cookshare.app',   'Sunday morning pitha',          'Banani DOHS', 23.7812, 90.4242, 933, false, null, null],
            ['imran@cookshare.app',  'Tehari for late lunch',         'Niketon',   23.7770, 90.4135, 144, true, 3, '280.00'],
            ['sumi@cookshare.app',   'Hilsa with mustard sauce',      'Mohakhali', 23.7700, 90.4100, 255, false, null, null],
        ];

        foreach ($stories as [$email, $dish, $area, $lat, $lng, $seed, $available, $portions, $price]) {
            $cook = $cookModels[$email];
            Story::firstOrCreate(
                ['user_id' => $cook->id, 'dish_name' => $dish],
                [
                    'photo_url' => "https://picsum.photos/seed/{$seed}/720/1280",
                    'caption' => $available ? "Fresh and ready — message me on WhatsApp." : "Just had to share this!",
                    'lat' => $lat,
                    'lng' => $lng,
                    'is_available' => $available,
                    'portions_total' => $portions,
                    'price' => $price,
                    'pickup_area' => $available ? $area : null,
                    'whatsapp_at_post' => $cook->whatsapp_number,
                    'expires_at' => now()->addHours((int) config('cookshare.story_ttl_hours', 24)),
                ]
            );
        }
    }
}
