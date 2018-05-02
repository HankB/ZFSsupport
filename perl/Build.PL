use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'MyZFS',
    license        => 'MIT',
    dist_abstract  => 'cleanupo snapshots and snapshot dumps',
    dist_author    => 'Hank Barta <hbarta@gmail.com>',
    build_requires => {
        'Test::More'    => '0.10',
        'Sub::Override' => '0.09',
        'File::Touch'   => '0.11',
    },
);

$builder->create_build_script();
