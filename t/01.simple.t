#!/usr/bin/env perl
use 5.10.0;
use strict;
use warnings;
use Test::More;
use DateTime;
use Blawd;
use Git::PurePerl;
use Path::Class;

use aliased 'Git::PurePerl::NewObject::Blob';
use aliased 'Git::PurePerl::NewDirectoryEntry' => 'DirectoryEntry';
use aliased 'Git::PurePerl::NewObject::Tree';
use aliased 'Git::PurePerl::Actor';
use aliased 'Git::PurePerl::NewObject::Commit';

my $directory = 'blog-bare.git';

dir($directory)->rmtree;
my $blog = Blawd->new( repo => $directory, init => 1 );
is( $blog->_storage->all_objects->all, 0, 'no posts' );

# SET UP A POST
our $hello;
{
    my $blob = Blob->new( content => 'Hello World' );
    $blog->_storage->put_object($blob);
    $hello = DirectoryEntry->new(
        mode     => '100644',
        filename => 'hello',
        sha1     => $blob->sha1,
    );
    my $tree = Tree->new( directory_entries => [$hello] );

    $blog->_storage->put_object($tree);

    my $commit = Commit->new(
        tree   => $tree->sha1,
        author => Actor->new(
            name  => 'Flexo',
            email => 'flexo@example.org',
        ),
        authored_time => DateTime->from_epoch( epoch => 1240341681 ),
        committer     => Actor->new(
            name  => 'Bender',
            email => 'bender@example.org',
        ),
        committed_time => DateTime->from_epoch( epoch => 1240341682 ),
        comment        => 'Post',
    );

    $blog->_storage->put_object($commit);
}

# TEST THE POST
ok( my @entries = $blog->find_entries, 'got entries' );
is( scalar @entries, 1, 'got only one post' );
ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;
is( $entries[0]->mtime, DateTime->from_epoch( epoch => 1240341682 ),
    'right mtime' );
is( $entries[0]->author->name, 'Flexo',       'right author' );
is( $entries[0]->content,      'Hello World', 'right content' );
is( $entries[0]->render,       'Hello World', 'render correctly' );

isa_ok( $blog->index, 'Blawd::Index' );
is( $blog->index->render, "Hello World", 'index renders' );

# SET UP A SECOND POST
{
    my $blob = Blob->new( content => 'Goodbye World' );
    $blog->_storage->put_object($blob);

    my $tree = Tree->new(
        directory_entries => [
            DirectoryEntry->new(
                mode     => '100644',
                filename => 'goodbye',
                sha1     => $blob->sha1,
            ),
            $hello,
        ]
    );

    $blog->_storage->put_object($tree);

    my $commit = Commit->new(
        tree   => $tree->sha1,
        author => Actor->new(
            name  => 'Flexo',
            email => 'flexo@example.org',
        ),
        authored_time => DateTime->from_epoch( epoch => 1240341691 ),
        committer     => Actor->new(
            name  => 'Bender',
            email => 'bender@example.org',
        ),
        committed_time => DateTime->from_epoch( epoch => 1240341692 ),
        comment        => 'Post',
    );
    $blog->_storage->put_object($commit);
}

ok($blog->clear_index, 'cleared the index');
ok( @entries = $blog->find_entries, 'got entries' );
is( scalar @entries, 2, 'got two posts' );
ok( $_->does('Blawd::Entry::API'), 'does Blawd::Entry::API' ) for @entries;
is( $entries[-1]->mtime, DateTime->from_epoch( epoch => 1240341692 ),
    'right mtime' );
is( $entries[-1]->author->name, 'Flexo',       'right author' );
is( $entries[-1]->content,      'Hello World', 'right content' );
is( $entries[-1]->render,       'Hello World', 'render correctly' );

isa_ok( $blog->index, 'Blawd::Index' );
is($blog->index->size, 2, 'index is the right size');
is( $blog->index->render, "Hello World\nGoodbye World", 'index renders' );

done_testing;

dir($directory)->rmtree;
