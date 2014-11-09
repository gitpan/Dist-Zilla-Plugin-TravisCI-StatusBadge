package Dist::Zilla::Plugin::TravisCI::StatusBadge;

# ABSTRACT: Get Travis CI status badge for your markdown README

use strict;
use warnings;
use Path::Tiny 0.004;
use Encode qw(encode);
use Moose;
use namespace::autoclean;
use Dist::Zilla::File::OnDisk;

our $VERSION = '0.005'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with qw(
    Dist::Zilla::Role::AfterBuild
);

has readme => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'README.md' },
);

has user => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_user',
);

has repo => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_repo',
);

has branch => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'master' },
);

has vector => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
);


sub after_build {
    my ($self) = @_;

    # fill user/repo using distmeta
    $self->_try_distmeta()      unless $self->has_user && $self->has_repo;

    unless ( $self->has_user && $self->has_repo ) {
        $self->log( "Missing option: user or repo." );
        return;
    }

    my $file  = $self->zilla->root->file($self->readme);

    if (-e $file) {
        $self->log("Override " . $self->readme . " in root directory.");
        my $readme = Dist::Zilla::File::OnDisk->new(name => "$file");

        my $edited;

        foreach my $line (split /\n/, $readme->content) {
            if ($line =~ /^# VERSION/) {
                $self->log("Inject build status badge");
                $line = join '' =>
                    sprintf(
                        "[![Build Status](https://travis-ci.org/%s/%s.%s?branch=%s)](https://travis-ci.org/%s/%s)\n\n" =>
                        $self->user, $self->repo,
                        ( $self->vector ? 'svg' : 'png' ),
                        $self->branch, $self->user, $self->repo
                    ),
                    $line;
            }
            $edited .= $line . "\n";
        }

        my $encoding =
            $readme->can('encoding')
                ? $readme->encoding
                : 'raw'                             # Dist::Zilla pre-5.0
                ;

        Path::Tiny::path($file)->spew_raw(
            $encoding eq 'raw'
                ? $edited
                : encode($encoding, $edited)
        );
    }
    else {
        $self->log("Not found " . $self->readme . " in root directory.");
        return;
    }

    return;
}


# attempt to fill user/repo using distmeta resources
sub _try_distmeta {
    my ( $self ) = @_;

    my $meta = $self->zilla->distmeta;

    return      unless exists $meta->{resources};

    # possible list of sources for user/repo:
    # resources.repository.web
    # resources.repository.url
    # resources.homepage
    my @sources = (
        (
            exists $meta->{resources}{repository}
                ? grep { defined $_ } @{ $meta->{resources}{repository} }{qw( web url )}
                : ()
        ),
        (
            exists $meta->{resources}{homepage}
                ? $meta->{resources}{homepage}
                : ()
        ),
    );

    # remove duplicates
    @sources = do {
        my %seen = map { $_ => 1 } @sources;
        sort keys %seen;
    };

    for my $source ( @sources ) {
        # dont overwrite
        last        if $self->has_user && $self->has_repo;

        next        unless $source =~ m/github\.com/i;

        # taken from Dist/Zilla/Plugin/GithubMeta.pm
        # thanks to BINGOS!
        my ( $user, $repo ) = $source =~ m{
            github\.com              # the domain
            [:/] ([^/]+)             # the username (: for ssh, / for http)
            /    ([^/]+?) (?:\.git)? # the repo name
            $
        }ix;

        next        unless defined $user && defined $repo;

        $self->user( $user );
        $self->repo( $repo );

        last;
    }
}

__PACKAGE__->meta->make_immutable;

1; # End of Dist::Zilla::Plugin::TravisCI::StatusBadge

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TravisCI::StatusBadge - Get Travis CI status badge for your markdown README

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    ; in dist.ini
    [TravisCI::StatusBadge]
    user = johndoe
    repo = p5-John-Doe-Stuff
    branch = foo        ;; "master" by default
    vector = 1          ;; SVG image

    ; or just
    [TravisCI::StatusBadge]
    ;; shortcut for "png image; master branch; user/repo from meta resources"

=head1 DESCRIPTION

Scans dist files if a C<README.md> file has found, a Travis CI C<build status> badge will be added before the B<VERSION> header.
Use L<Dist::Zilla::Plugin::ReadmeAnyFromPod> in markdown mode or any other plugin to generate README.md.

=for Pod::Coverage after_build

=for Pod::Coverage _try_distmeta

=head1 OPTIONS

=head2 readme

The name of file to inject build status badge. Default value is C<README.md>.

=head2 user

Github username. Might be obtained automatically (if not given) from META resources (C<resources.homepage>,
C<resources.repository.web>, C<resources.repository.url>).

=head2 repo

Github repository name. Might be obtained automatically (if not given) from META resources
(C<resources.homepage>, C<resources.repository.web>, C<resources.repository.url>).

=head2 branch

Branch name which build status should be shown. Optional. Default value is B<master>.

=head2 vector

Use vector representation (SVG) of build status image. Optional. Default value is B<false> which means
using of the raster representation (PNG).

=head1 SEE ALSO

L<https://travis-ci.org>

L<Dist::Zilla::Plugin::ReadmeAnyFromPod>

L<Dist::Zilla::Plugin::GithubMeta>

L<Dist::Zilla::Role::AfterBuild>

L<Dist::Zilla>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
