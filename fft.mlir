module {
  func.func @main() { 
    %N = arith.constant 8 : index // int N
    %alloc_0 = memref.alloc() : memref<8xf64> // input array
    %alloc_1 = memref.alloc() : memref<8xf64> // output real
    %alloc_2 = memref.alloc() : memref<8xf64> //output imag
    // indexes of the arrays
    %c0 = arith.constant 0 : index 
    %c1 = arith.constant 1 : index
    %c2 = arith.constant 2 : index
    %c3 = arith.constant 3 : index
    %c4 = arith.constant 4 : index
    %c5 = arith.constant 5 : index
    %c6 = arith.constant 6 : index
    %c7 = arith.constant 7 : index
    // storing values in the input array
    %cst_0 = arith.constant 0.000000e+00 : f64
    affine.store %cst_0, %alloc_0[%c0] : memref<8xf64>
    %cst_1 = arith.constant 1.000000e+01 : f64
    affine.store %cst_1, %alloc_0[%c1] : memref<8xf64>
    %cst_2 = arith.constant 3.400000e+02 : f64
    affine.store %cst_2, %alloc_0[%c2] : memref<8xf64>
    %cst_3 = arith.constant 3.000000e+01 : f64
    affine.store %cst_3, %alloc_0[%c3] : memref<8xf64>
    %cst_4 = arith.constant 4.000000e+01 : f64
    affine.store %cst_4, %alloc_0[%c4] : memref<8xf64>
    %cst_5 = arith.constant 1.100000e+02 : f64
    affine.store %cst_5, %alloc_0[%c5] : memref<8xf64>
    %cst_6 = arith.constant 6.000000e+01 : f64
    affine.store %cst_6, %alloc_0[%c6] : memref<8xf64>
    %cst_7 = arith.constant 2.500000e+02 : f64
    affine.store %cst_7, %alloc_0[%c7] : memref<8xf64>
    // temp memory creation
    %alloc_temp_real = memref.alloc() : memref<8xf64>
    %alloc_temp_imag = memref.alloc() : memref<8xf64>
    // storing values in temp real and temp imag
    affine.for %arg0 = 0 to %N {
      %val = affine.load %alloc_0[%arg0] : memref<8xf64>
      affine.store %val, %alloc_temp_real[%arg0] : memref<8xf64>
      %zero = arith.constant 0.0 : f64
      affine.store %zero, %alloc_temp_imag[%arg0] : memref<8xf64>
    }
    
    // bit reversal
    // Allocate reversed arrays
    %alloc_reversed_real = memref.alloc() : memref<8xf64>
    %alloc_reversed_imag = memref.alloc() : memref<8xf64>

    // Bit reversal constants
    %c1_i64 = arith.constant 1 : i64
    %c2_i64 = arith.constant 2 : i64

    // Perform bit reversal
    affine.for %i = 0 to %N {
      %i_val = arith.index_cast %i : index to i64

      %bit0 = arith.andi %i_val, %c1_i64 : i64
      %i_val_shr1 = arith.shrui %i_val, %c1_i64 : i64
      %bit1 = arith.andi %i_val_shr1, %c1_i64 : i64
      %i_val_shr2 = arith.shrui %i_val, %c2_i64 : i64
      %bit2 = arith.andi %i_val_shr2, %c1_i64 : i64

      %rev_bit0 = arith.shli %bit0, %c2_i64 : i64
      %rev_bit1 = arith.shli %bit1, %c1_i64 : i64
      %rev_temp = arith.ori %rev_bit0, %rev_bit1 : i64
      %rev = arith.ori %rev_temp, %bit2 : i64

      %reversed_i = arith.index_cast %rev : i64 to index

      %real_val = affine.load %alloc_temp_real[%i] : memref<8xf64>
      %imag_val = affine.load %alloc_temp_imag[%i] : memref<8xf64>

      memref.store %real_val, %alloc_reversed_real[%reversed_i] : memref<8xf64>
      memref.store %imag_val, %alloc_reversed_imag[%reversed_i] : memref<8xf64>
    }

    // Copy reversed arrays back to temp arrays
    affine.for %i = 0 to %N {
      %real_val = affine.load %alloc_reversed_real[%i] : memref<8xf64>
      %imag_val = affine.load %alloc_reversed_imag[%i] : memref<8xf64>
      affine.store %real_val, %alloc_temp_real[%i] : memref<8xf64>
      affine.store %imag_val, %alloc_temp_imag[%i] : memref<8xf64>
    }

    // Cooley-Tukey FFT implementation
    %stages = arith.constant 3 : index  // log2(8) = 3

    // Constants for complex arithmetic
    %pi = arith.constant 3.14159265358979323846 : f64
    %neg2 = arith.constant -2.0 : f64

    scf.for %stage = %c0 to %stages step %c1 {
      %half_size = arith.shli %c1, %stage : index
      %full_size = arith.shli %half_size, %c1 : index
      
      scf.for %start = %c0 to %N step %full_size {
        scf.for %j = %c0 to %half_size step %c1 {
          %even_index = arith.addi %start, %j : index
          %odd_index = arith.addi %even_index, %half_size : index
          
          // Calculate twiddle factor
          %j_i64 = arith.index_cast %j : index to i64
          %j_f64 = arith.sitofp %j_i64 : i64 to f64
          %full_size_i64 = arith.index_cast %full_size : index to i64
          %full_size_f64 = arith.sitofp %full_size_i64 : i64 to f64
          %angle_div = arith.divf %j_f64, %full_size_f64 : f64
          %angle_mul = arith.mulf %neg2, %angle_div : f64
          %angle_final = arith.mulf %pi, %angle_mul : f64
          
          // exp(-2j * pi * j / full_size)
          %cos = math.cos %angle_final : f64
          %sin = math.sin %angle_final : f64
          
          // Load odd value
          %odd_real = memref.load %alloc_temp_real[%odd_index] : memref<8xf64>
          %odd_imag = memref.load %alloc_temp_imag[%odd_index] : memref<8xf64>
          
          // Multiply by twiddle factor
          %odd_real_cos = arith.mulf %odd_real, %cos : f64
          %odd_imag_sin = arith.mulf %odd_imag, %sin : f64
          %t_real = arith.subf %odd_real_cos, %odd_imag_sin : f64

          %odd_real_sin = arith.mulf %odd_real, %sin : f64
          %odd_imag_cos = arith.mulf %odd_imag, %cos : f64
          %t_imag = arith.addf %odd_real_sin, %odd_imag_cos : f64
          
          // Load even value
          %even_real = memref.load %alloc_temp_real[%even_index] : memref<8xf64>
          %even_imag = memref.load %alloc_temp_imag[%even_index] : memref<8xf64>
          
          // Butterfly operation
          %new_even_real = arith.addf %even_real, %t_real : f64
          %new_even_imag = arith.addf %even_imag, %t_imag : f64
          %new_odd_real = arith.subf %even_real, %t_real : f64
          %new_odd_imag = arith.subf %even_imag, %t_imag : f64
          
          // Store results
          memref.store %new_even_real, %alloc_temp_real[%even_index] : memref<8xf64>
          memref.store %new_even_imag, %alloc_temp_imag[%even_index] : memref<8xf64>
          memref.store %new_odd_real, %alloc_temp_real[%odd_index] : memref<8xf64>
          memref.store %new_odd_imag, %alloc_temp_imag[%odd_index] : memref<8xf64>
        }
      }
    }
    // copying from temp to alloc_#
    affine.for %i = 0 to %N {
      %r = affine.load %alloc_temp_real[%i] : memref<8xf64>
      %im = affine.load %alloc_temp_imag[%i] : memref<8xf64>
      affine.store %r, %alloc_1[%i] : memref<8xf64>
      affine.store %im, %alloc_2[%i] : memref<8xf64>
    }

    dsp.print %alloc_1 : memref<8xf64>
    dsp.print %alloc_2 : memref<8xf64>

    // Deallocate memories
    memref.dealloc %alloc_temp_real : memref<8xf64>
    memref.dealloc %alloc_temp_imag : memref<8xf64>
    memref.dealloc %alloc_reversed_real : memref<8xf64>
    memref.dealloc %alloc_reversed_imag : memref<8xf64>

    return
  }
}