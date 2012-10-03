use strict;
use warnings;
use utf8;
use Lingua::JA::TermExtractor;
use Test::More;
use Test::Fatal;
use Test::Requires qw/TokyoCabinet/;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $df_file = './df/utf8.tch';

my %config = (
    driver          => 'TokyoCabinet',
    df_file         => $df_file,
    fetch_df        => 0,
    pos1_filter     => [],
    pos2_filter     => [],
    pos3_filter     => [],
    ng_word         => [],
    tf_min          => 1,
    term_length_min => 1,
    term_length_max => 30,
    df_min          => 0,
    db_auto         => 0,
);

my $extractor = Lingua::JA::TermExtractor->new(\%config);
my $exception = exception{ $extractor->extract('テスト'); };
like($exception, qr/not opened/, 'not opened');

$extractor->db_open('read');
$exception = exception{ $extractor->extract('テスト'); };
is($exception, undef, 'opened');
$extractor->db_close;

$extractor = Lingua::JA::TermExtractor->new(\%config);
$exception = exception{ $extractor->tfidf('テスト'); };
like($exception, qr/not opened/, 'not opened (tfidf)');

$extractor->db_open('read');
$exception = exception{ $extractor->tfidf('テスト'); };
is($exception, undef, 'opened (tfidf)');
$extractor->db_close;

$config{'db_auto'} = 1;
$extractor = Lingua::JA::TermExtractor->new(\%config);
$exception = exception{ $extractor->tfidf('テスト'); };
is($exception, undef, 'tfidf auto db open');

$config{'db_auto'} = 1;
$extractor = Lingua::JA::TermExtractor->new(\%config);
$exception = exception{ $extractor->extract('テスト'); };
is($exception, undef, 'extract auto db open');

done_testing;
