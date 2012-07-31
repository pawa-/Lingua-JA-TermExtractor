package Lingua::JA::TermExtractor;

use 5.008_001;
use strict;
use warnings;

use Carp ();
use parent 'Lingua::JA::TFWebIDF';
use Lingua::JA::TermExtractor::Result;

our $VERSION = '0.03';


sub new
{
    my $class = shift;
    my %args  = (ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    $args{idf_type} = 3 unless defined $args{idf_type};
    $args{db_auto}  = 1 unless defined $args{db_auto};

    my %options;
    $options{k1} = defined $args{k1} ? delete $args{k1} : 2.0;
    $options{b}  = defined $args{b}  ? delete $args{b}  : 0.75;

    if ($args{db_auto})
    {
        $options{db_auto_child} = 1;
        $args{db_auto}          = 0;
    }
    else { $options{db_auto_child} = 0; }

    my $self = $class->SUPER::new(\%args);
    $self->{k1}            = $options{k1};
    $self->{b}             = $options{b};
    $self->{db_auto_child} = $options{db_auto_child};

    return $self;
}

sub extract
{
    my ($self, $arg) = @_;

    my ($k1, $b) = ($self->{k1}, $self->{b});
    my $db_auto  = $self->{db_auto_child};
    my $fetch_df = $self->{fetch_df};
    my $fetch_unk_word_df = $self->{fetch_unk_word_df};

    my $data = {};

    if (ref $arg eq 'ARRAY')
    {
        # dl: document length

        my $dl_sum = 0;
        $dl_sum += length $_ for @{$arg};

        if ($dl_sum == 0)
        {
            Carp::carp("array is empty");
            return;
        }

        my $dl_avg = $dl_sum / scalar @{$arg};


        if ($db_auto)
        {
            if ($fetch_df || $fetch_unk_word_df) { $self->db_open('write'); }
            else                                 { $self->db_open('read');  }
        }

        for my $text (@{$arg})
        {
            my $tfidf = $self->SUPER::tfidf($text)->dump;
            my $dl    = length $text;

            for my $word (keys %{$tfidf})
            {
                my ($tf, $idf, $df) = ($tfidf->{$word}{tf}, $tfidf->{$word}{idf}, $tfidf->{$word}{df});

                $data->{$word}{tf}     += $tf;
                $data->{$word}{idf}     = $idf;
                $data->{$word}{df}      = $df;
                $data->{$word}{info}    = $tfidf->{$word}{info}    unless exists $data->{$word}{info};
                $data->{$word}{unknown} = $tfidf->{$word}{unknown} unless exists $data->{$word}{unknown};

                $data->{$word}{bm25}
                    +=
                    (
                          ( $tf * ($k1 + 1) )
                        / ( $tf + $k1 * (1 - $b + $b * ($dl / $dl_avg)) )
                    )
                    * $idf
                    ;
            }
        }
    }
    else
    {

        if ($db_auto)
        {
            if ($fetch_df || $fetch_unk_word_df) { $self->db_open('write'); }
            else                                 { $self->db_open('read');  }
        }

        $data = $self->SUPER::tfidf($arg)->dump;

        #for my $word (keys %{$data})
        #{
        #    my ($tf, $idf) = ($data->{$word}{tf}, $data->{$word}{idf});
        #
        #    $data->{$word}{bm25}
        #        =
        #        (
        #              ( $tf * ($k1 + 1) )
        #            / ($tf + $k1)
        #        )
        #        * $idf
        #        ;
        #}
    }

    $self->db_close if $db_auto;

    return Lingua::JA::TermExtractor::Result->new($data);
}

sub tfidf
{
    my ($self, $arg) = @_;
    my $data = $self->SUPER::tfidf($arg, $self->{db_auto_child})->dump;
    return Lingua::JA::TermExtractor::Result->new($data);
}

'nyan!';

__END__

=encoding utf8

=head1 NAME

Lingua::JA::TermExtractor - Term Extractor

=for test_synopsis
my ($appid, $document, @documents);

=head1 SYNOPSIS

  use Lingua::JA::TermExtractor;
  use utf8;
  use feature qw/say/;
  use Data::Printer;

  my $extractor = Lingua::JA::TermExtractor->new(
      api               => 'YahooPremium',
      appid             => $appid,
      fetch_df          => 1,
      Furl_HTTP         => { timeout => 3 },
      driver            => 'TokyoTyrant',
      df_file           => 'localhost:1978',
      pos1_filter       => [qw/非自立 代名詞 数 ナイ形容詞語幹 副詞可能 サ変接続/],
      term_length_min   => 2,
      tf_min            => 2,
      df_min            => 1_0000,
      df_max            => 1000_0000,
      ng_word           => [qw/編集 本人 自身 自分 たち さん/],
      fetch_unk_word_df => 0,
      concat_max        => 100,
  );

  p $extractor->extract($document)->dump;
  p $extractor->extract(\@documents)->dump;

  for my $result (@{ $extractor->extract(\@documents)->list(50) })
  {
      my ($word, $score) = each %{$result};

      say "$word: $score";
  }


=head1 DESCRIPTION

Lingua::JA::TermExtractor is a term extractor.
This extracts terms from a document or documents.

=head1 METHODS

=head2 new( %config || \%config )

Creates a new Lingua::JA::TermExtractor instance.

The following configuration is used if you don't set %config.

  KEY                 DEFAULT VALUE
  -----------         ---------------
  k1                  2.0
  b                   0.75

  pos1_filter         [qw/非自立 代名詞 数 ナイ形容詞語幹 副詞可能 接尾/]
  pos2_filter         []
  pos3_filter         []
  ng_word             []
  term_length_min     2
  term_length_max     30
  concat_max          30
  tf_min              1
  df_min              0
  df_max              250_0000_0000
  fetch_unk_word_df   0
  db_auto             1

  idf_type            3
  api                 'Yahoo'
  appid               undef
  driver              'Storable'
  df_file             undef
  fetch_df            1
  expires_in          365
  documents           250_0000_0000
  Furl_HTTP           undef

=over 4

=item k1 => $value

The weight of term frequency(TF).

=item b => $value

The weight of document length normalization.

=item pos(1|2|3)_filter, ng_word, term_length_(min|max), concat_max, tf_min, df_(min|max), fetch_unk_word_df, db_auto

See L<Lingua::JA::TFWebIDF>.

=item idf_type, api, appid, driver, df_file, fetch_df, expires_in, documents, Furl_HTTP

See L<Lingua::JA::WebIDF>.

=back

=head2 extract( $document || \@documents )

Extracts terms from $document or \@documents.
Word segmentation and POS tagging are done with MeCab.

=head2 tfidf, tf

See L<Lingua::JA::TFWebIDF>.

=head2 idf, df, purge, db_open, db_close

See L<Lingua::JA::WebIDF>.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

L<Lingua::JA::WebIDF>

L<Lingua::JA::WebIDF::Driver::TokyoTyrant>

L<Lingua::JA::TFWebIDF>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
