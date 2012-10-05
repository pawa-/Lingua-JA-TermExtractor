package Lingua::JA::TermExtractor;

use 5.008_001;
use strict;
use warnings;

use Carp ();
use parent 'Lingua::JA::TFWebIDF';
use Lingua::JA::TermExtractor::Result;

our $VERSION = '0.10';


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

    my $data = {};

    if ($db_auto)
    {
        if ($fetch_df) { $self->db_open('write'); }
        else           { $self->db_open('read');  }
    }

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

        my $num_local_doc = scalar @{$arg};
        my $dl_avg        = $dl_sum / $num_local_doc;

        my @dl_and_tfidf;

        for my $text (@{$arg})
        {
            push( @dl_and_tfidf, { dl => length $text, tfidf => $self->SUPER::tfidf($text)->dump } );
        }

        for my $dl_and_tfidf (@dl_and_tfidf)
        {
            my $tfidf = $dl_and_tfidf->{tfidf};
            my $dl    = $dl_and_tfidf->{dl};

            for my $word (keys %{$tfidf})
            {
                my ($tf, $idf) = ($tfidf->{$word}{tf}, $tfidf->{$word}{idf});

                $data->{$word}{tf}      += $tf;
                $data->{$word}{idf}      = $idf;
                $data->{$word}{df}       = $tfidf->{$word}{df};
                #$data->{$word}{tfidf}   += $tfidf->{$word}{tfidf};
                $data->{$word}{local_df} = _count_local_df(\@dl_and_tfidf, $word) unless exists $data->{$word}{local_df};
                $data->{$word}{info}     = $tfidf->{$word}{info}    unless exists $data->{$word}{info};
                $data->{$word}{unknown}  = $tfidf->{$word}{unknown} unless exists $data->{$word}{unknown};

                $data->{$word}{bm25}
                    +=
                    (
                          ( $tf * ($k1 + 1) )
                        / ( $tf + $k1 * (1 - $b + $b * ($dl / $dl_avg)) )
                    )
                    *
                        (
                            $idf
                          + log( $num_local_doc / ($num_local_doc - $data->{$word}{local_df} + 1) )
                        )
                    ;
            }
        }
    }
    else
    {
        if (ref $arg eq 'SCALAR') { $data = $self->SUPER::tfidf($arg)->dump;  }
        else                      { $data = $self->SUPER::tfidf(\$arg)->dump; }
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

sub _count_local_df
{
    my ($dl_and_tfidf_ref, $word) = @_;

    my $cnt = 0;

    for my $df_and_tfidf (@{$dl_and_tfidf_ref})
    {
        $cnt++ if exists $df_and_tfidf->{tfidf}{$word};
    }

    return $cnt;
}

1;

__END__

=encoding utf8

=head1 NAME

Lingua::JA::TermExtractor - Term Extractor

=for test_synopsis
my ($document, @documents);

=head1 SYNOPSIS

  use Lingua::JA::TermExtractor;
  use utf8;
  use feature qw/say/;
  use Data::Printer;

  my $extractor = Lingua::JA::TermExtractor->new(
      df_file           => './df.tch', # Please download from http://misc.pawafuru.com/webidf/.
      pos1_filter       => [qw/非自立 代名詞 ナイ形容詞語幹 副詞可能 サ変接続/],
      ng_word           => [qw/編集 本人 自身 自分 たち さん/],
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
This extracts terms from one or more documents
and sorts them based on their TF*WebIDF or BM25
scores.

=head1 METHODS

=head2 new( %config || \%config )

Creates a new Lingua::JA::TermExtractor instance.

The following configuration is used if you don't set %config.

  KEY                 DEFAULT VALUE
  -----------         ---------------
  k1                  2.0
  b                   0.75

  pos1_filter         [qw/非自立 代名詞 ナイ形容詞語幹 副詞可能/]
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
  guess_df            1

  idf_type            3
  api                 'YahooPremium'
  appid               undef
  driver              'TokyoCabinet'
  df_file             './df.tch'
  fetch_df            0
  expires_in          365
  documents           250_0000_0000
  Furl_HTTP           undef
  verbose             0

=over 4

=item k1 => $weight

The weight of term frequency(TF).

=item b => $weight

The weight of document length normalization.

=item pos(1|2|3)_filter, ng_word, term_length_(min|max), concat_max, tf_min, df_(min|max), fetch_unk_word_df, db_auto, guess_df

See L<Lingua::JA::TFWebIDF>.

=item idf_type, api, appid, driver, df_file, fetch_df, expires_in, documents, Furl_HTTP, verbose

See L<Lingua::JA::WebIDF>.

=back

=head2 extract( $document || \@documents )

Extracts terms from $document or \@documents
and sorts them based on their TF*WebIDF or BM25
scores.

If $document, TF*WebIDF is used.
If \@documents, BM25 is used.

Word segmentation and POS tagging are done via MeCab.

=head2 tfidf, tf

See L<Lingua::JA::TFWebIDF>.

=head2 idf, df, purge, db_open, db_close

See L<Lingua::JA::WebIDF>.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

L<Lingua::JA::TFWebIDF>

L<Lingua::JA::WebIDF>

L<Lingua::JA::WebIDF::Driver::TokyoTyrant>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
