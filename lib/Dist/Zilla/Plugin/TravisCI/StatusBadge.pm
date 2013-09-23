package Dist::Zilla::Plugin::TravisCI::StatusBadge;

# ABSTRACT: Get Travis CI status badge for your markdown README

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Dist::Zilla::File::OnDisk;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with qw(
    Dist::Zilla::Role::InstallTool
);

has readme => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'README.md' },
);

has user => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { '' },
);

has repo => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { '' },
);

sub setup_installer {
    my ($self) = @_;

    if ($self->user eq '' || $self->repo eq '') {
        $self->log("Missing option: user or repo.");
        return;
    }

    my $file  = $self->zilla->root->file($self->readme);

    if (-e $file) {
        $self->log("Override " . $self->readme . " in root directory.");
        my $readme = Dist::Zilla::File::OnDisk->new(name => "$file");

        my $edited;

        require File::Slurp;

        foreach my $line (split /\n/, $readme->content) {
            if ($line =~ /^# VERSION/) {
                $self->log("Inject build status badge");
                $line = join '' =>
                    sprintf(
                        "[![build status](https://secure.travis-ci.org/%s/%s.png)](https://travis-ci.org/%s/%s)\n\n" =>
                        ($self->user, $self->repo) x 2
                    ),
                    $line;
            }
            $edited .= $line . "\n";
        }

        File::Slurp::write_file("$file", {binmode => ':raw'}, $edited);
    }
    else {
        $self->log("Not found " . $self->readme . " in root directory.");
        return;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1; # End of Dist::Zilla::Plugin::TravisCI::StatusBadge

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::TravisCI::StatusBadge - Get Travis CI status badge for your markdown README

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    ; in dist.ini
    [TravisCI::StatusBadge]
    user = johndoe
    repo = p5-John-Doe-Stuff

=head1 DESCRIPTION

Scans dist files if a C<README.md> file has found, a Travis CI 'build status' badge will be added before the B<VERSION> header.
Use L<Dist::Zilla::Plugin:::ReadmeAnyFromPod> in markdown mode or any other plugin to generate README.md.

=head1 OPTIONS

=head2 readme

The name of file to inject build status badge. Default value is C<README.md>.

=head2 user

Travis CI username. Required.

=head2 repo

Travis CI repository name. Required.

=head1 SEE ALSO

L<https://travis-ci.org>

L<Dist::Zilla::Plugin:::ReadmeAnyFromPod>

L<Dist::Zilla>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
