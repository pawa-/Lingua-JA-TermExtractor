use strict;
use warnings;
use utf8;
use Lingua::JA::TermExtractor;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my %config = (
    driver            => 'Storable',
    df_file           => './df/flagged_utf8.st',
    fetch_df          => 0,
    pos1_filter       => [],
    pos2_filter       => [],
    pos3_filter       => [],
    ng_word           => [],
    tf_min            => 1,
    term_length_min   => 1,
    term_length_max   => 30,
    df_min            => 0,
    concat_max        => 0,
);

my $text  = 'テスト';
my $texts = texts();

my $extractor = Lingua::JA::TermExtractor->new(\%config);
ds_check( $extractor->tfidf($text)->dump, 'SCALAR', 'TFIDF' );
ds_check( $extractor->tfidf(\$text)->dump, 'SCALAR', 'TFIDF' );
ds_check( $extractor->extract($text)->dump, 'SCALAR' );
ds_check( $extractor->extract(\$text)->dump, 'SCALAR' );
ds_check( $extractor->extract($texts)->dump );

$config{concat_max} = 100;
$extractor = Lingua::JA::TermExtractor->new(\%config);
ds_check_concat( $extractor->tfidf($text)->dump, 'SCALAR', 'TFIDF' );
ds_check_concat( $extractor->tfidf(\$text)->dump, 'SCALAR', 'TFIDF' );
ds_check_concat( $extractor->extract($text)->dump, 'SCALAR' );
ds_check_concat( $extractor->extract(\$text)->dump, 'SCALAR' );
ds_check_concat( $extractor->extract($texts)->dump );

done_testing;


sub ds_check
{
    my ($data, $type, $algorithm) = @_;

    $type      = 'ARRAY' unless defined $type;
    $algorithm = 'BM25'  unless defined $algorithm;

    for my $word (keys %{$data})
    {
        like($data->{$word}{df},       qr/^[0-9]+$/,    'df');
        like($data->{$word}{idf},      qr/^[\.0-9]+$/,  'idf');
        like($data->{$word}{info},     qr/\*/,          'info');
        like($data->{$word}{unknown},  qr/^[01]$/,      'unknown');
        like($data->{$word}{tf},       qr/^[0-9]+$/,    'tf');
        like($data->{$word}{tfidf},    qr/^[\.0-9]+$/,  'tfidf')     if $type eq 'SCALAR';
        like($data->{$word}{bm25},     qr/^[\.0-9]+$/,  'bm25')      if $type ne 'SCALAR' && $algorithm ne 'TFIDF';
        like($data->{$word}{local_df}, qr/^[0-9]+$/,    'local_df')  if $type ne 'SCALAR' && $algorithm ne 'TFIDF';
    }
}

sub ds_check_concat
{
    my ($data, $type, $algorithm) = @_;

    $type      = 'ARRAY' unless defined $type;
    $algorithm = 'BM25'  unless defined $algorithm;

    for my $word (keys %{$data})
    {
        like($data->{$word}{df},    qr/^[0-9]+$/,   'df');
        like($data->{$word}{idf},   qr/^[\.0-9]+$/, 'idf');
        is(ref $data->{$word}{info},    'ARRAY',    'info');
        is(ref $data->{$word}{unknown}, 'ARRAY',    'unknown');
        like("@{ $data->{$word}{info} }",    qr/^(.+,.+)+$/, 'content of info');
        like("@{ $data->{$word}{unknown} }", qr/^[01 ]+$/,   'content of unknown');
        like($data->{$word}{tf},    qr/^[0-9]+$/,   'tf');
        like($data->{$word}{tfidf}, qr/^[\.0-9]+$/, 'tfidf') if $type eq 'SCALAR';
        like($data->{$word}{bm25},  qr/^[\.0-9]+$/, 'bm25')  if $type ne 'SCALAR' && $algorithm ne 'TFIDF';
        like($data->{$word}{local_df}, qr/^[0-9]+$/,    'local_df') if $type ne 'SCALAR' && $algorithm ne 'TFIDF';
    }
}

sub texts
{
    return
    [
    "
    今日は今年２試合目の草野球の試合でした。対戦相手は前回と同じ所でした。

    非常に締まってて、すごく良い試合でした。結果は６対４で勝ち。今年初勝利！フルへッ！

    試合は１番セカンドで出ましたが、「死球」「三振」「補ゴ」「ファールチップ三振」「三ゴロ」の４打数０安打。２番打者が早い段階で打ったので盗塁もできませんでした。良いとこなしですわ。

    守備はダイビングキャッチのファインプレーが１回、ボテボテのゴロのエラーが１回、あとは無難にこなしました。難しい球ダイビングで捕ってボテボテのゴロをエラーって上手いのやら下手なのやら・・・。

    でも、やっぱり本職はセカンドですね！

    相手チームは見た目３０代ぐらいの人が多くてこっちは２０代前半が中心。相手チームの投手はかなりおじいさんって感じで球速も遅いんだけど、コーナーにバシバシ変化球決めてくるので、ピッチャーが変わるまで両チーム０行進でした。

    足当たるやろと思ったのが、グググっと曲がってストライクになったりでビビった。球速なくても変化球とコントロールあれば抑えれるもんなんやなぁ。

    さあ、アルゴリズムの勉強しないとな。
    ",

    "
    今日は男だらけの草野球でした。

    かなり集まりが良かったけど、試合相手が見つからなかったらしく、練習でした。

    キャッチボール
    ４５分耐久ノック
    怒涛の盗塁練習
    灼熱の３打席バッティング

    をしました。

    ４５分耐久ノック：サード守ったけど、特に問題なし。強いて言えば送球が若干乱れました。

    怒涛の盗塁練習：盗塁は得意なのでセカンドの守備をしました。捕球は良い感じでしたが、ボールがランナーにぶつかる場面が３回ぐらいありました。ボールデッドじゃなくてインプレーのままのはずなので、ぶつかる前にセカンドが前に出て取るべきですかね。

    灼熱の３打席バッティング：「遊飛」「三ゴロ」「左安」

    卒研にハマって肉バットすら振ってないのに打てるのかよって感じでしたが、最後は身体の近くで捕らえてライナーでホームベースから７２ｍに設置されているレフトのネットに直撃して（飛距離８０ｍ届かんぐらい？）良い感じでした。

    草野球やってるときが一番楽しい。プログラミングも楽しいけど、草野球のときみたいに嫌なこと全てを忘れることはできませんし、成功したときのあの充実感はスポーツでないと得られません！？
    ",

    "
    四球スリーベース、それは盗塁が得意な打者に許されたチート技。主に草野球で使用可能。

    今日はまた対外試合。１３時過ぎプレイボール。

    １番セカンド俺。四球もらったので二盗してノーアウトランナー二塁。その後に三盗を決めてノーアウトランナー三塁。打者にも四球でノーアウトランナー１塁、３塁。ここまで来れば余裕で点が入ります。最高の試合の始まり方でした。

    今日はいろいろあってみんな非常に締まってて５対６ぐらいで勝ちました。自分はその後は打撃ではあまり活躍できず・・・。２日前の素振りで手の皮ビロンビロンにしてしまったのが結構響いた。

    まあでも、四球スリーベースという攻撃手法を編み出せたのは良かった。打撃だけでツーベース打つのは結構困難、ましてやスリーベースなんて・・・。それと同等の結果が四球もらうだけで達成できるなんて素晴らしい。

    草野球での盗塁成功率はまだ１００％で牽制死もゼロ。打撃の調子が回復するまでゴキブリみたいにカサカサと塁上をはいずり回ります。
    ",

    "
    今日も草野球。とにかく暑かった。多分大阪では今年一番暑い。ボチボチ研究のための勉強に集中したいけど、前の試合のバッティングがダメだったので逝きました。長打打てなくないけど、長打狙うと極端に確実性が損なわれるので、今日は単打だけを狙いました。長打打つより単打打って盗塁するほうが確率は高い。

    今日は８番セカンド出ました。相手の玉はすごく・・・大きいですかなりゆっくり（しかしかなり速い球も持ってる）がメインだったので、身体がキャッチャー方向に向くぐらいフルスイングしたかったけど、トスバッティング時みたいにゆっくり打ちました。ただ、バットはいつもより重いバットを使いました。

    狙い通り、２回裏ぐらいで２アウトランナー２塁でバッターpawaだったので、速い球は捨てて、ゆっくりボールをゆっくり振ってしっかり芯で捕らえました。重いバットなのでゆっくり振っても芯で捕らえてやればライナーになってくれます。三遊間をライナーで抜けてタイムリーヒット。そしてその後盗塁でしてやったり。

    ただ、その後の２か３打席目でワンアウト満塁でアウトカウントも塁もあまりの暑さで考えられずに適当にサードゴロ打ったのは大いに反省すべき。結果は３打数１安打１打点１盗塁でなんとか及第点？

    試合は、みんな暑さ（３６度）でヘロヘロで後半に逆転されて負けました。自分もぐったり。

    もう２時間グランドとってたけど、あまりの暑さで中止でした。甲子園みたいに死ぬ気で練習してないので体が持ちませんでした。

    かなりドタバタしてたけど、明日から研究の勉強やりまくりましょか。
    ",

    "
    今日は今年初めての草野球の試合でした。１月にも１回試合ありましたが、さすがに寒いと思って見送ったら今日のほうが寒いという・・・。でも、ウィンドブレーカーを着たら気温ほどは寒く感じませんでした。

    対戦相手のチームはいつもよりは強くありませんでした。こっち先攻で自分は１番センターで出ました。

    初打席は芯で捕らえましたがレフトライナー。後続も倒れ０点。微妙な流れのまま０対０で試合は進みました。

    ２打席目はインコース低めの球を芯で捕らえましたがレフトが背走キャッチ。途中で１点取られて０対１。嫌なムードが漂い始めます。

    ３打席目はノーアウト１，２塁で回ってきました。真ん中やや高めの球を芯で捕らえて左中間をフライでぎりぎり破るヒットでノーアウト満塁で出塁しました。ここから２者が凡退して２アウト満塁になりました。その後、見方のデッドボールやらフィルダースチョイスやらで３対１で逆転。

    こちらもフォアボールでランナーためて打たれる自滅パターンで終わってみれば３対３の引き分け。今日は勝つべきでしたね。自分は「左飛」「左飛」「左安」の.333でした。終わってみれば３の１ですが、今日はバッティングが覚醒していて、初めて反省ノートには「問題なし」としか書くことがなかった。この調子を維持したいですな。

    やっぱり野球は面白い。野球最高！

    TOEICの勉強のペースも上げていくぜ！
    ",
    ];
}
