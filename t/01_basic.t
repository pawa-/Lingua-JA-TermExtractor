use strict;
use warnings;
use Lingua::JA::TermExtractor;
use Test::More;
use Test::Fatal;
use Test::Warn;


can_ok('Lingua::JA::TermExtractor',
    qw/new idf df tfidf tf db_open db_close purge extract/);

my $exception = exception{ Lingua::JA::TermExtractor->new({ c => 1 }); };
like($exception, qr/Unknown/, 'Unknown option');

my $extractor = Lingua::JA::TermExtractor->new(
    appid => 'test',
    k1    => '2.0',
    b     => '0.75',
);

isa_ok($extractor, 'Lingua::JA::TermExtractor');

warning_like { $extractor->extract([]); } qr/empty/, 'empty array';

done_testing;
