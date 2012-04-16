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

## ffffound_fetch_originals_from_db.rb

Using the database, this attempts to revisit the original image URL stored by ffffound and to download the image (which is hopefully of higher resolution than ffffound's copy). These images are saved to an 'originals' directory.

### Known issues

The script should save images with their ffffound ID, but doesn't.

Flickr images that are made private or deleted aren't correctly detected.

Other images are downloaded even when no longer valid image files.


## Experimental scripts

These may included hardcoded filenames, or simply not work. Use with caution.

## ffffound_from_flickr.rb

For images posted from Flickr, find favourites count (and compare to the ffffound count) and (optionally) mark as a favourite at Flickr (requires Flickr auth).

## ffffound_to_tumblr.rb

Uploads the ffffound copies of images to Tumblr as drafts, and publishes (and backdates) them. Very much a work in progress, with authentication being particularly weird.

## make_sequence.rb

Makes an image sequence suitable for importing to QuickTime to be animated.