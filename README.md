# Grepimg
A hacked together Ruby script to search through image files for a piece of text, ala grep-style.

## Installation
Requires tesseract (for OCR) and imagemagick (for scaling to improve accuracy) to be installed on your system and
depends on the `rtesseract` and `rmagick` gems.

## Usage
Case-sensitive text search:
```
ruby grepimg.rb "Text to Find" *.jpg
```

Case-insensitive text search:
```
ruby grepimg.rb -i "text to find" *.jpg
```

Regular expression search (can be combined with -i):
```
ruby grepimg.rb -e "foo.*bar" *.jpg
```

Piping in files to search from:
```
find . | ruby grepimg.rb foo
```
