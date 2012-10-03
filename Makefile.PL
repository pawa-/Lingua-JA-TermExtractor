use inc::Module::Install;

name     'Lingua-JA-TermExtractor';
all_from 'lib/Lingua/JA/TermExtractor.pm';

requires 'Carp';
requires 'Lingua::JA::TFWebIDF' => 0.40;

test_requires 'Test::More' => 0.88; # done_testing
test_requires 'Test::Fatal';
test_requires 'Test::Warn' => 0.20;
test_requires 'Test::Requires';

tests 't/*.t';
author_tests 'xt';

readme_from 'lib/Lingua/JA/TermExtractor.pm';

resources(
    license    => 'http://dev.perl.org/licenses',
    repository => 'https://github.com/pawa-/Lingua-JA-TermExtractor',
    bugtracker => 'https://github.com/pawa-/Lingua-JA-TermExtractor/issues',
);

WriteAll;
