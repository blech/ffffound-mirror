# ffffound-mirror

This is a collection of (more or less working) Ruby scripts to archive (and, eventually, mirror) ffffound archives for a user.

The scripts use scraping, since ffffound have no published API. They comes with no 
guarantees, and are published under the MIT licence.

The main scripts are:

## ffffound_mirror_db.rb

This is the main archiving script, which takes one argument: the username to mirror. It also takes an optional second argument, post, which finds only posted images (as opposed to all images).

It produces a folder full of images named according to ffffound's ID scheme, and a SQLite 3 database which can be used to find the original source and other information about the image. The image is at ffffound's 450px resolution.

### Possible issues

I'm not sure I've fixed the directory making sections. If you get errors, manually create images and db directories.

## fetch_originals.rb

Using the database, this attempts to revisit the original image URL stored by ffffound and to download the image (as long as it's higher resolution than ffffound's copy). These images are saved to an 'originals' directory inside 'images', with the same ffffound ID 
as the counterpart in the images/ directory.

### Known issues

* Other images may be downloaded if the error page is larger than the image size.
* Filename suffixes can be wrong.

## Experimental scripts

These may included hardcoded filenames, or simply not work. Use with caution.

## ffffound_from_flickr.rb

For images posted from Flickr, find favourites count (and compare to the ffffound count) and (optionally) mark as a favourite at Flickr (requires Flickr auth).

## ffffound_to_tumblr.rb

Uploads the ffffound copies of images to Tumblr as drafts, and publishes (and backdates) them. Very much a work in progress, with authentication being particularly weird.

This also runs into Tumblr's daily post limits. Beware.

## make_sequence.rb

Makes an image sequence suitable for importing to QuickTime to be animated. This 
doesn't know about the new images/originals/ path layout.