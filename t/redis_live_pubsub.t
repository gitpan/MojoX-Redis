#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mojo::IOLoop;
use utf8;

plan skip_all => 'Setup $REDIS_SERVER'
  unless $ENV{REDIS_SERVER};

plan tests => 3;

use_ok 'MojoX::Redis';

my $loop = Mojo::IOLoop->singleton;

my $redis = new_ok 'MojoX::Redis' =>
  [server => $ENV{REDIS_SERVER}, timeout => 5, ioloop => $loop];


my $redis2 = new_ok 'MojoX::Redis' =>
  [server => $ENV{REDIS_SERVER}, timeout => 5, ioloop => $loop];

my $result = [];

$redis->del("test.1")->del("test.2")->subscribe(
    "test.1", "test.2",
    sub {
        my ($redis, $r) = @_;
        push @$result, $r;
        $redis->stop if scalar @$result == 2;
    }
);

$loop->timer(0.5 => sub { $redis2->publish("test.1" => "ok1") });
$loop->timer(0.7 => sub { $redis->unsubscribe("test.1") });
$loop->timer(0.9 => sub { $redis2->publish("test.2" => "ok2") });
$loop->timer(2   => sub { $loop->stop });

$redis->start;

use Data::Dumper;
print Dumper $result;
