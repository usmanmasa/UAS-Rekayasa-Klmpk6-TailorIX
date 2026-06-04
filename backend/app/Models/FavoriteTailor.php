<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FavoriteTailor extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'tailor_id',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function tailor()
    {
        return $this->belongsTo(User::class, 'tailor_id');
    }
}
