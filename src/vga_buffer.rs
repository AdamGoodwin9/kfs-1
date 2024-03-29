use volatile::Volatile;
use spin::Mutex;
use lazy_static::lazy_static;
use core::fmt;

#[allow(dead_code)] // Necessary to avoid warnings for unused code
#[derive(Debug, Clone, Copy, PartialEq, Eq)] // Implement Debug, Clone, Copy, PartialEq, and Eq traits
// Debug allows us to print the enum variant with {:?} aka human-readable output
// Copy allow the enum to be copied instead of moved (Clone allow the enum to be cloned, which is a superset of Copy)
// PartialEq and Eq allow us to compare the enum variants ('==' and '!=', and that every comparison is reflexive, symmetric, and transitive)
#[repr(u8)] // Represent the enum as an unsigned 8-bit integer (1 byte)
pub enum Color {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(transparent)] // Ensure that the struct has the same memory layout as its single field
struct ColorCode(u8);

impl ColorCode {
    fn new(foreground: Color, background: Color) -> ColorCode {
        ColorCode((background as u8) << 4 | (foreground as u8))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(C)] // Ensure that the struct has the same memory layout as a C struct (usually random in Rust)
struct ScreenChar {
    ascii_character: u8,
    color_code: ColorCode,
}

const BUFFER_HEIGHT: usize = 25;
const BUFFER_WIDTH: usize = 80;

#[repr(transparent)]
struct Buffer {
    chars: [[Volatile<ScreenChar>; BUFFER_WIDTH]; BUFFER_HEIGHT], // In rust, the syntax is [[Type; sizeX]; sizeY]. Also, We
    // use Volatile to ensure that the compiler doesn't optimize away writes to the buffer
}

pub struct Writer {
    column_position: usize, // The current column position
    color_code: ColorCode, // The current color code
    buffer: &'static mut Buffer, // The buffer to write to, we use 'static to ensure that the buffer lives for the entire duration 
    // of the program and make it mutable to allow writing to it (we specify &mut so that we don't take ownership of the buffer)
}

impl Writer {
    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(), // If the byte is a newline character, move to the next line
            byte => {
                if self.column_position >= BUFFER_WIDTH { // If the column position is at the end of the buffer, move to the next line
                    self.new_line();
                }
                // Otherwise, write the byte to the buffer
                let row = BUFFER_HEIGHT - 1;
                let col = self.column_position;

                let color_code = self.color_code;
                self.buffer.chars[row][col].write(ScreenChar {
                    ascii_character: byte,
                    color_code,
                });
                self.column_position += 1;
            }
        }
    }

    // Write all the contents of the buffer up one row and clear the last row
    fn new_line(&mut self) { 
        for row in 1..BUFFER_HEIGHT {
            for col in 0..BUFFER_WIDTH {
                let character = self.buffer.chars[row][col].read();
                self.buffer.chars[row - 1][col].write(character);
            }
        }
        self.clear_row(BUFFER_HEIGHT - 1);
        self.column_position = 0;
    }

    // Write over the contents of a row with blank characters
    fn clear_row(&mut self, row: usize) {
        let blank = ScreenChar {
            ascii_character: b' ',
            color_code: self.color_code,
        };
        for col in 0..BUFFER_WIDTH {
            self.buffer.chars[row][col].write(blank);
        }
    }
}

impl Writer {
    pub fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                // printable ASCII byte or newline
                0x20..=0x7e | b'\n' => self.write_byte(byte),
                // not part of printable ASCII range
                _ => self.write_byte(0xfe), // print '■' character
            }

        }
    }
}

impl fmt::Write for Writer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.write_string(s);
        Ok(())
    }
}

lazy_static! { // Create a static variable that is initialized at runtime instead of compile time
    pub static ref WRITER: Mutex<Writer> = Mutex::new(Writer { // Create a new mutex-protected Writer so that we can avoid race conditions
        column_position: 0,
        color_code: ColorCode::new(Color::Magenta, Color::Black),
        buffer: unsafe { &mut *(0xb8000 as *mut Buffer) },
    });
}

#[doc(hidden)] // Hide the function from the generated documentation
pub fn _print(args: fmt::Arguments) {
    use fmt::Write;
    WRITER.lock().write_fmt(args).unwrap(); // Lock the mutex and write the formatted string to the buffer (unwrap is used to panic
    // if an error occurs but we only return Ok(()), so it will never panic)
}