use strict;
use warnings;
use utf8;
use Lingua::JA::TermExtractor;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $extractor = Lingua::JA::TermExtractor->new(
    driver   => 'Storable',
    df_file  => './df/flagged_utf8.st',
    fetch_df => 0,
);

my $text = '世界';

for my $result (@{ $extractor->extract($text)->list })
{
    my ($word, $weight) = each %{$result};

    is($word, '世界', 'word');
    like($weight, qr/^[0-9\.]+$/, 'weight');
}

for my $result (@{ $extractor->extract(\$text)->list })
{
    my ($word, $weight) = each %{$result};

    is($word, '世界', 'word');
    like($weight, qr/^[0-9\.]+$/, 'weight');
}

done_testing;
