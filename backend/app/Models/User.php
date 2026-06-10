<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'address',
        'profile_photo_url',
        'role',
        'shop_name',
        'location_lat',
        'location_lng',
        'specializations',
        'device_token',
        'portfolio',
        'is_available',
        'rating',
        'rating_count',
        'verification_document_url',
        'is_verified',
        'terms_accepted',
        'terms_accepted_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'specializations' => 'array',
        'portfolio' => 'array',
        'is_available' => 'boolean',
        'is_verified' => 'boolean',
        'terms_accepted' => 'boolean',
        'terms_accepted_at' => 'datetime',
        'rating' => 'decimal:2',
    ];

    public function favoriteTailors()
    {
        return $this->belongsToMany(User::class, 'favorite_tailors', 'customer_id', 'tailor_id');
    }

    public function favorites()
    {
        return $this->hasMany(FavoriteTailor::class, 'customer_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'customer_id');
    }

    public function tailorOrders()
    {
        return $this->hasMany(Order::class, 'tailor_id');
    }

    public function reviewsAsTailor()
    {
        return $this->hasMany(Review::class, 'tailor_id');
    }

    public function reviewsAsCustomer()
    {
        return $this->hasMany(Review::class, 'customer_id');
    }

    public function isTailor(): bool
    {
        return $this->role === 'tailor';
    }

    public function isCustomer(): bool
    {
        return $this->role === 'customer';
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}
