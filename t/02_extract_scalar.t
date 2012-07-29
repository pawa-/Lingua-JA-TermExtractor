use strict;
use warnings;
use utf8;
use Lingua::JA::TermExtractor;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $extractor = Lingua::JA::TermExtractor->new(
    appid    => 'test',
    fetch_df => 0,
);

for my $result (@{ $extractor->extract("世界")->list })
{
    my ($word, $score) = each %{$result};

    is($word, '世界', 'word');
    like($score, qr/^[0-9\.]+$/, 'score');
}

done_testing;
