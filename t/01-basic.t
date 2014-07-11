use strict;
use warnings;
use Test::Most tests => 19;

use Test::DZil;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::TravisCI::StatusBadge;

my $md = [
    'ReadmeAnyFromPod', 'ReadmeMdInRoot' => {
        type     => 'markdown',
        filename => 'README.md',
        location => 'root',
    }
];

my @configs = (
    config_okay => [ $md, [ 'TravisCI::StatusBadge' => { repo => 'p5-John-Doe', user => 'johndoe' } ] ],
        qr{\Q[![Build Status]\E.*travis-ci\.org.*master.*johndoe/p5-John-Doe.*},
    okay_branch => [ $md, [ 'TravisCI::StatusBadge' => { repo => 'p5-John-Doe', user => 'johndoe', branch => 'foo22' } ] ],
        qr{\Q[![Build Status]\E.*travis-ci\.org.*foo22.*johndoe/p5-John-Doe.*},
    okay_vector => [ $md, [ 'TravisCI::StatusBadge' => { repo => 'p5-John-Doe', user => 'johndoe', vector => 1 } ] ],
        qr{\Q[![Build Status]\E.*travis-ci\.org.*svg\?branch.*johndoe/p5-John-Doe.*},
    missed_both => [ $md, [ 'TravisCI::StatusBadge' => { } ] ],
        qr{[^\Q[![Build Status]\E]},
    missed_user => [ $md, [ 'TravisCI::StatusBadge' => { repo => 'p5-John-Doe' } ] ],
        qr{[^\Q[![Build Status]\E]},
    missed_repo => [ $md, [ 'TravisCI::StatusBadge' => { user => 'johndoe' } ] ],
        qr{[^\Q[![Build Status]\E]},
);

my $no_readme = [
    $md, [ 'TravisCI::StatusBadge' => { repo => 'p5-John-Doe', user => 'johndoe', readme => 'README.markdown' } ],
];

my $builder = sub {
    Builder->from_config(
        {   dist_root => 'corpus/dist/DZT' },
        {   add_files => { 'source/dist.ini' => simple_ini('GatherDir', @_) } },
    );
};

while (my ($case, $config, $result) = splice @configs, 0, 3) {
    SKIP: {
        my $tzil = $builder->(@$config);

        lives_ok { $tzil->build; }                                          "$case dist built okay";

        my $content = eval { $tzil->slurp_file('source/README.md'); };
        ok $content, "$case README.md found"  or skip "$case README.md fails", 1;

        like $content, qr/$result/,                                         "$case Travis CI build status badge okay";
    }
}

my $tzil = $builder->(@$no_readme);
lives_ok { $tzil->build; }                                                  "wrong README.md dist built okay";

1;
