# ZFS support - Perl components

## Components

`myzfs.pl` will cleanup
after (or before) `update-snapshot.sh`. Heavy lifting is put in MyZFS.pm
in order to make testing easier. Other scripts are support and/or testing
scripts. There are hooks in `update-snapshot.sh` to execute external 
commands before or after the other processing.

## Requirements

* Perl module `Sub::Override` (`apt install libsub-override-perl` on Ubuntu 16.04 and Debian 9)
* Perl module  `File::Touch` (`apt install libfile-touch-perl` on Debian Stretch)
* Perl module  `Module::Build` (`apt install libmodule-build-perl`  on Ubuntu 16.04)
* Perl module  `Devel::Cover` (`apt install libdevel-cover-perl` on Ubuntu 16.04)

### myzfs.pl

Logic to destroy older snapshots and delete old snapshot dumps.

### myzfs.t

Test script for `MyZFS.pm`

### MyZFS.pm

Module to implement the lower level logic in a testable form.

## Building

Following guidelines from `https://stackoverflow.com/questions/533553/perl-build-unit-testing-code-coverage-a-complete-working-example`


```cd perl
perl Build manifest
perl Build.PL
perl Build test
perl Build testcover
```

## Testing

Either 

```text
perl Build test
```

or

```text
./t/myzfs.t 
```

## Installing

Put the module `MyZFS.pm` somewhere convenient. The following command lists possibilities:
`perl -e 'print join "\n", @INC;'` and on my system shows

```perl
hbarta@grandidier:~/Documents/ZFSsupport/perl$ perl -e 'print join "\n", @INC;'
/etc/perl
/usr/local/lib/x86_64-linux-gnu/perl/5.22.1
/usr/local/share/perl/5.22.1
/usr/lib/x86_64-linux-gnu/perl5/5.22
/usr/share/perl5
/usr/lib/x86_64-linux-gnu/perl/5.22
/usr/share/perl/5.22
/usr/local/lib/site_perl
/usr/lib/x86_64-linux-gnu/perl-base
.hbarta@grandidier:~/Documents/ZFSsupport/perl$ 
```

Copy the script `myzfs.pl` to a convenient location such as /usr/local/sbin

### my install commands

```text
cd perl
sudo mkdir /usr/local/lib/site_perl
sudo cp lib/MyZFS.pm /usr/local/lib/site_perl
sudo cp myzfs.pl /usr/local/sbin
```

## Errata

During testing I performed multiple tsts in one day by renaming the most recent snapshot by appending `.n` to the name. (e.g. `.0`, `.1` and so on.) As a result fewer than the desired number of snapshot dumps were preserved.
