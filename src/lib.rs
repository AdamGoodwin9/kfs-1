#![no_std] // don't link the Rust standard library
#![no_main] // disable all Rust-level entry points

use core::panic::PanicInfo;
mod vga_buffer;
mod helpers;

/// This function is called on panic.
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}

#[no_mangle] // don't mangle the name of this function (changing the name)
pub extern "C" fn kernel_main()
{
    // this function is the entry point
    println!("Hello KFS-1{}", "!");
    println!("
     /$$   /$$  /$$$$$$ 
    | $$  | $$ /$$__  $$
    | $$  | $$|__/  \\ $$
    | $$$$$$$$  /$$$$$$/
    |_____  $$ /$$____/ 
          | $$| $$      
          | $$| $$$$$$$$
          |__/|________/
                        ");
    print!("Made by:\nAssxios and Goody\n");
    loop {}
}