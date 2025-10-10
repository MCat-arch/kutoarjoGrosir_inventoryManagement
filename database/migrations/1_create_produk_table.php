<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('produk', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('jenis_produk_id');
            $table->string('namaProduk');
            $table->decimal('harga_produksi',15,2);
            $table->decimal('harga_jual',15,2);
            $table->string('qty_produk');
            $table->timestamps();
             $table->foreign('jenis_produk_id')->references('id')->on('jenis_produk')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('produk');
    }
};
