# Linux Password Generator

A secure and user-friendly password generator written in Bash. This project creates cryptographically random passwords with customizable lengths, password strength indicators, clipboard support, and file-saving functionality.

## Features

* Generate secure random passwords using `/dev/urandom`
* Custom password length (4–128 characters)
* Includes:

  * Uppercase letters (A-Z)
  * Lowercase letters (a-z)
  * Numbers (0-9)
  * Special characters
* Password strength indicator
* Copy generated passwords to the clipboard
* Save passwords to a text file
* Generate multiple passwords in a single session
* Input validation and error handling
* Compatible with Linux and Git Bash on Windows

## Technologies Used

* Bash Shell Scripting
* Linux Command-Line Utilities
* `/dev/urandom`
* `tr`
* `grep`
* `head`
* `fold`
* `shuf`
* `xclip`, `xsel`, and `clip` (optional clipboard support)

## Requirements

* Bash 4.0 or later
* Linux distribution or Git Bash on Windows

Optional dependencies for clipboard support:

### Ubuntu/Debian

```bash
sudo apt install xclip
```

### Fedora

```bash
sudo dnf install xclip
```

### Arch Linux

```bash
sudo pacman -S xclip
```

## Installation

Clone the repository:

```bash
git clone https://github.com/your-username/linux-password-generator.git
cd linux-password-generator
```

Make the script executable:

```bash
chmod +x password_generator.sh
```

## Usage

Run the script:

```bash
./password_generator.sh
```

or

```bash
bash password_generator.sh
```

## Example Output

```text
========================================
        Welcome to Password Generator
========================================

Enter desired password length (4 - 128): 12

Generating your password...

Password : A7#kP9@mQ2!x
Strength : Strong

Copy password to clipboard? (yes/no):
Save password to 'generated_password.txt'? (yes/no):
Generate another password? (yes/no):
```

## Project Structure

```text
linux-password-generator/
│
├── password_generator.sh
└── README.md
```

## Learning Objectives

This project demonstrates:

* Bash scripting fundamentals
* Functions and modular programming
* Input validation
* File handling
* Secure random number generation
* Linux command-line utilities
* Cross-platform compatibility

## Future Improvements

* Password customization options
* Exclude ambiguous characters
* Generate passphrases
* Password history encryption
* Command-line arguments support


Student |Aspiring AI Security Researcher | Linux Enthusiast | Exploring Cybersecurity, Machine Learning Security, and Open Source Technologies.

Passionate about building projects that combine Linux, automation, and AI security while continuously learning about secure systems and emerging technologies.

## License

This project is released under the MIT License.