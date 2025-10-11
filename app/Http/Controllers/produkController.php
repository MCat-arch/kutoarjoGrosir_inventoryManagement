<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\produk;
use DB;
use App\Http\Resources\ResponsResources;
use Illuminate\Support\Facades\Validator;

class produkController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
        $produk = Produk::join('jenis_produk', 'jenis_produk.id', '=', 'produk.jenis_produk_id')
        ->select('produk.namaProduk', 'produk.harga_produksi', 'produk.harga_jual', 'produk.qty_produk')
        ->get();
        return new ResponsResources(true, 'Data Produk', $produk);

        
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
       
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
         $produk = Produk::create([
            'jenis_produk_id'=>$request->jenis_produk_id,
            'namaProduk'=>$request->namaProduk,
            'harga_produksi'=>$request->harga_produksi,
            'harga_jual'=>$request->harga_jual,
            'qty_produk'=>$request->qty_produk
        ]);
        return new ResponsResources(true, 'Berhasil Menambahkan data', $produk);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
        $produk = Produk::join('jenis_produk', 'jenis_produk.id', '=', 'produk.jenis_produk_id')
        ->select('produk.namaProduk', 'produk.harga_produksi', 'produk.harga_jual', 'produk.qty_produk')
        ->where('produk.id', '=', $id)
        ->get();
        return new ResponsResources(true, 'Detail Produk', $produk);

    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function updateNama(Request $request, string $id)
    {
        //
        $validator = Validator::make($request->all(),
        ['namaProduk'=>'required'], ['namaProduk.required'=>'Nama Wajib Diisi']);
        if($validator->fails()){
            return response()->json($validator->errors(), 422);
        }
        $produk = Produk::findOrFail($id);
        $produk->update([
            'namaProduk'=>$request->namaProduk,

        ]);
       
        return new ResponsResources(true, "data Nama berhasil diubah", $produk);
    }

    public function updateStok(Request $request, string $id)
    {
          $validator = Validator::make($request->all(),
        ['qty_produk'=>'required'], ['qty_produk.required'=>'kuantitas Wajib Diisi']);
        if($validator->fails()){
            return response()->json($validator->errors(), 422);
        }
        $produk = Produk::findOrFail($id);
        $produk->update([
            'qty_produk'=>$request->qty_produk,
        ]);

        return new ResponsResources(true, "data stok berhasil diubah", $produk);
    }

    public function updateHargaProduksi(Request $request, string $id)
    {

          $validator = Validator::make($request->all(),
        ['harga_produksi'=>'required'], ['harga_produksi.required'=>'harga Produksi Wajib Diisi']);
        if($validator->fails()){
            return response()->json($validator->errors(), 422);
        }
        $produk= Produk::findOrFail($id);
        $produk->update([
            'harga_produksi'=>$request->harga_produksi,
        ]);


        return new ResponsResources(true, "data harga produksi berhasil diubah", $produk);
    }

    public function updateHargaJual(Request $request, string $id)
    {
          $validator = Validator::make($request->all(),
        ['harga_jual'=>'required'], ['harga_jual.required'=>'harga_jual Wajib Diisi']);
        if($validator->fails()){
            return response()->json($validator->errors(), 422);
        }
        $produk = Produk::findOrFail($id);
        $produk->update([
            'harga_jual'=>$request->harga_jual,
        ]);

        return new ResponsResources(true, "data harga jual berhasil diubah", $produk);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
        $produk = Produk::whereId($id)->first();
        $produk->delete();
        return new ResponsResources(true, 'Data Berhasil Dihapus', $produk);
    }
}
