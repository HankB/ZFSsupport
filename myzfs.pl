#!/usr/bin/perl

# just call 'main()'

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

use lib '.';
use MyZFS qw(main);

main();
