# `aw88399_acf.bin` firmware extraction guide

All credit for this method goes to [Nadim Kobeissi](https://github.com/nadimkobeissi/16iax10h-linux-sound-saga?tab=readme-ov-file#credits) and [Gergo K.](https://bugzilla.kernel.org/show_bug.cgi?id=218329#c18).

## Step 1: Download the Windows audio driver
You can find the Lenovo Windows audio driver for the AMD model (16AFR10H, 83RU) [at this link](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/legion-series/legion-pro-7-16afr10h/83ru/83ructo1ww/downloads/driver-list/component?name=audio&id=3AA7F1C4-5B2A-453C-9CE2-B8FCDA8B69BA), and for the Intel version (16IAX10H, 83F5) [at this one](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/legion-series/legion-pro-7-16iax10h/83f5/downloads/driver-list/component?name=Audio&id=3AA7F1C4-5B2A-453C-9CE2-B8FCDA8B69BA). Please note that, although the final extracted package will look slightly different, the file we are after is exactly the same irrespective of which driver you download (you can verify that yourself by using `diff`); I am simply providing both links for completeness.

## Step 2: Install `innoextract`
Install the `innoextract` package. This changes depending on your distro; for example, under Fedora Linux you can use:
```bash
sudo dnf install innoextract
```
and similarly for other distros.

## Step 3: Extract the .exe
Navigate to the folder where you saved the .exe file, then use innoextract on it:
```bash
innoextract <...>.exe
```
## Step 4: Locate and rename the binary file
After innoextract is done, you'll see a folder named `code$GetExtractPath$`. Navigate to the `Source` folder inside it, then look for a folder whose name contains `Awinic_smart_amp`. Inside you'll find a file called `AWDZ8399.bin`; copy it somewhere and rename it `aw88399_acf.bin`. We're done!
Again: please know that the inside of the `Source` folder will look slightly different between the Intel and AMD versions, but the file we care about is identical.
