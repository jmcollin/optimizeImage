Optimize Images
=========

Allow you to optimize and compress your images in batches


## Dependencies

* [**mozjpeg >= 3.1**](https://github.com/mozilla/mozjpeg)
* [**gifsicle**](https://github.com/kohler/gifsicle)
* [**pngcrush >= 1.7.85**](http://pmt.sourceforge.net/pngcrush/)
* [**pngquant >= 2.3.1**](https://github.com/pornel/pngquant)
* [**ImageMagick >= 6.7.7-10**](https://github.com/ImageMagick/ImageMagick)
* **libpng >= 1.6.17**


## Getting Started

To use this script, choose one of the following options to get started:

* Download the latest release of Optimize Images
* Fork this repository on GitHub


## Installation


**Locally**

Installing Optimize Images locally is a matter of just running the script in your project directory:

```
Natsuflame@debian:home # git clone https://github.com/jmcollin/optimizeImage.git
```

**Globally**

```
Natsuflame@debian:home # cd optimizeImage/
Natsuflame@debian:optimizeImage # cp optimizeImage.sh /usr/bin/optimizeImage
```

Instruction for **mozjpeg**

```
Natsuflame@debian:home # cd mozjpeg/build/
Natsuflame@debian:build # cp cjpeg /usr/bin/mozcjpeg
Natsuflame@debian:build # cp djpeg /usr/bin/mozdjpeg
Natsuflame@debian:build # cp jpegtran /usr/bin/mozjpegtran
```

## Usage

```
Usage: optimizeImage [OPTION]... SRC... DEST
  or   optimizeImage [OPTION]... SRC... [DEST]

Options
 -q 90, --quality 90         set quality (default ~ 90)
 -t jpg, png, gif            set image type (default ~ jpg)

 -d                          print dependencies
 --version                   print version number
(-h|-?) --help               show this help (-h is --help only if used alone)
```

## Example Usage
```
Natsuflame@debian:optimizeImage # optimizeImage -t png src/ /home/optimizeImage/test/
Clean directory
Optipmize image(s)
[✔] ./PrestaShopAddons.png

[✘] Original Size: 72.78 KB
[✔] Savings Size: 58.99 KB
[✔] % Savings: 19.44%

```

Original image:

![alt text](https://github.com/jmcollin/optimizeImage/blob/master/src/PrestaShopAddons.png "Original")


Optimize image:

![alt text](https://github.com/jmcollin/optimizeImage/blob/master/test/PrestaShopAddons.png "Optimize")

## Version
1.0.0

## Copyright and License

Copyright 2014 Jean-Marie Collin. Code released under the [MIT License](https://github.com/jmcollin/autoindex/blob/master/LICENSE) license.

Theme used Copyright 2014 Iron Summit Media Strategies, LLC. Code released under the [Apache 2.0](https://github.com/IronSummitMedia/startbootstrap-freelancer/blob/gh-pages/LICENSE) license.
