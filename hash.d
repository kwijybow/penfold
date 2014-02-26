import std.stdio, std.string, std.array, std.conv, std.algorithm;
import core.bitop;
import core.memory : GC;
import chess;
import position;
import tree;

struct Hash_Entry {
  ulong word1;
  ulong word2;
};

struct Pawn_Hash_Entry {
  ulong key;
  int score_mg, score_eg;
  ubyte defects_k[2];
  ubyte defects_e[2];
  ubyte defects_d[2];
  ubyte defects_q[2];
  ubyte all[2];
  ubyte passed[2];
};

struct Hpath_Entry {
  ulong path_sig;
  int hash_pathl;
  int hash_path_age;
  int hash_path_moves[MAXPLY];
};

int transposition_age;
int hash_table_size      = 33554432;
int hash_path_size       = 65536;
int pawn_hash_table_size = 1048576;
ulong hash_mask;
ulong pawn_hash_mask;
ulong hash_path_mask;

Hash_Entry* trans_ref;
Pawn_Hash_Entry* pawn_hash_table;
Hpath_Entry* hash_path;

void InitializeHashTables() {
  int i, side;
  int black = 0;
  int white = 1;
  
  trans_ref = cast(Hash_Entry*)GC.malloc(hash_table_size * Hash_Entry.sizeof, GC.BlkAttr.NO_SCAN);
  pawn_hash_table = cast(Pawn_Hash_Entry*)GC.malloc(hash_table_size * Pawn_Hash_Entry.sizeof, GC.BlkAttr.NO_SCAN);
  hash_path = cast(Hpath_Entry*)GC.malloc(hash_path_size * Hpath_Entry.sizeof, GC.BlkAttr.NO_SCAN);
  hash_mask = ((1UL << (bsr(to!ulong(hash_table_size)) - 2)) - 1) << 2;
  pawn_hash_mask = (1UL << bsr(to!ulong(pawn_hash_table_size))) - 1;
  hash_path_mask = (hash_path_size - 1) & ~15;

  transposition_age = 0;
  if (!trans_ref)
    return;
  for (i = 0; i < hash_table_size; i++) {
    (trans_ref + i).word1 = 0;
    (trans_ref + i).word2 = 0;
  }
  for (i = 0; i < hash_path_size; i++)
    (hash_path + i).hash_path_age = -99;
  if (!pawn_hash_table)
    return;
  for (i = 0; i < pawn_hash_table_size; i++) {
    (pawn_hash_table + i).key = 0;
    (pawn_hash_table + i).score_mg = 0;
    (pawn_hash_table + i).score_eg = 0;
    for (side = black; side <= white; side++) {
      (pawn_hash_table + i).defects_k[side] = 0;
      (pawn_hash_table + i).defects_e[side] = 0;
      (pawn_hash_table + i).defects_d[side] = 0;
      (pawn_hash_table + i).defects_q[side] = 0;
      (pawn_hash_table + i).all[side] = 0;
      (pawn_hash_table + i).passed[side] = 0;
    }
  }
}


ulong randoms[2][7][64] = [
  [
    [ 0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL ],
    [ 0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0xd1fc122dd721044cUL,
      0xa4159629bd0ce70eUL, 0xab5da9e9ae24ad63UL, 0x32e60a2983d1c843UL,
      0x3c3cf99dabf131aaUL, 0xd83283085553e1fdUL, 0x180370f4abada20fUL,
      0xa7db417ed5cef0f6UL, 0x8940b08b9b2fc0d4UL, 0x852d84b34edc83d2UL,
      0x068d4a5f2548652fUL, 0x35ce432f12163d2eUL, 0xc9ba66fee4843746UL,
      0xabccc0992b67af9eUL, 0x217f1caa6a824b26UL, 0x4a05addc1ea2e944UL,
      0xfe2312497bf4c414UL, 0x8495248ab305ee8fUL, 0xcb96c4247c24e036UL,
      0xab76533d29e3c6eaUL, 0xc0944c15e3c09778UL, 0x1053b4ccf6c024d6UL,
      0x8d96dda010ba133aUL, 0x9f59cef04505da02UL, 0x581ae15866c42214UL,
      0x3a61654f9da998bfUL, 0x47efd3ec19fb73c0UL, 0x2126b228fdb69cb5UL,
      0xbb2ff9574df0d641UL, 0x32b9d1ed571b84b8UL, 0x4f688c6727828a1fUL,
      0x576784e75cc9d113UL, 0x15e82e121ffd9115UL, 0xbc0156dbcef2a7deUL,
      0x6365ce9628bd842eUL, 0x3a898fc4ece11b80UL, 0xa6f7652af004d29fUL,
      0x5fa9ca7e22d71d72UL, 0x5a06111a2088be1fUL, 0x05aae96e3384dfe4UL,
      0xe697a8f517ab3d3fUL, 0x9d3c1d1302e84551UL, 0x6e0b75ab4901a6c9UL,
      0xd35c48fba6cf7eefUL, 0xc8ee1ca11e20a35eUL, 0x382637115387cc68UL,
      0x8d499580f4544852UL, 0x1e4a273c98576ebdUL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL ],
    [ 0x2009a159d9509cb5UL, 0x5fa8c13086419e55UL, 0xea13669343bcd4b9UL,
      0x3e47b851efbef3a4UL, 0x6caa31dec6814cc6UL, 0x992161e6ef2c2919UL,
      0x8bed069c11856a55UL, 0x5c73de210d683e98UL, 0xa7185f2616bd83c1UL,
      0xd7c04ef29cf3751eUL, 0x9f46f244eaf78bcfUL, 0x38f85c7bcda11a85UL,
      0x22f1e6aabfe845aaUL, 0xa8aa67f9237dbb68UL, 0x90e2e582b1c84a64UL,
      0x5c685bafc31b3c9fUL, 0xc031fe468f6f6967UL, 0x8d75aa382752602aUL,
      0x244475599eceffd5UL, 0x0d0cfcd52bb265d4UL, 0xda433164b4750dc1UL,
      0x85dfeab10d5752d6UL, 0x7225a1188a0376ebUL, 0xa8be7b123a102607UL,
      0x603b914a4429875eUL, 0x399be2aedab54c3bUL, 0x58d916991d8a5cc4UL,
      0x35b8f864e4685bdbUL, 0x46739c9baf790ac0UL, 0xd1327ef186fb215aUL,
      0x140368fd88e26668UL, 0xd38e499b69fa1e25UL, 0xc96f5a7d211f3f9fUL,
      0x97655506a678b4bcUL, 0x7f8ddfb015f07d87UL, 0xbf7bfed396840428UL,
      0xfd2f0668eb41e684UL, 0x24936e7db2759b2dUL, 0x267a311ebcd14f08UL,
      0xf5a13e0e1d60b856UL, 0x69f15803d26af16aUL, 0x82fac9552fa58953UL,
      0xd71ea59c19c54beaUL, 0x62fdb302c66279d4UL, 0xf0c1baa7e1513de5UL,
      0x363454db33ee5ef4UL, 0xab4045843a34f2e0UL, 0x73f10c94a39100fdUL,
      0x0a86593ec58517e8UL, 0xae96e568385585deUL, 0x608a57252ef6f020UL,
      0x39cac56cc61f3368UL, 0x44a6a43e32a682b4UL, 0xa085261969416c01UL,
      0xbb870177729e6283UL, 0x1276bdc2fc1b7238UL, 0x77bcdc0127c4da80UL,
      0xbf16bb430520dde5UL, 0x153a63a94e385bddUL, 0x95104c33771f4a98UL,
      0xb0ff0dfa8ef47265UL, 0xc48762efcfbadae4UL, 0xf70e5b4dae84cfd0UL,
      0x250cabf0859b323bUL ],
    [ 0xf71c3f6b2fd5891cUL, 0x5d5675218dd4da7eUL, 0xd8e7b9cd991893a1UL,
      0xe4e1af2cf1bcb046UL, 0xa762655491b63283UL, 0xd8dc072d881ba73aUL,
      0xdb9cdd7d25570179UL, 0x76618a18da1cfd9aUL, 0xe4ed6cee7fb62d0cUL,
      0xfebc55cf05ef2fbfUL, 0x9a9f5c4a59c51554UL, 0xea91c3d8f98c3ecfUL,
      0x2f71c5493a5be25aUL, 0x8c4d65413c6bbfe6UL, 0x9f06ed35f9a2eac6UL,
      0x178831e02b8775b2UL, 0x10a3d155d65cd6c1UL, 0x4b7a69b028a0cd53UL,
      0xd7b84fb5e0de02f0UL, 0x9e266498ec93bb5cUL, 0xea0e4ad3f773090dUL,
      0x4cf4b1acc505eb02UL, 0x11bea6e26eff78fdUL, 0x7986363d8e9c8b02UL,
      0xff2ca02deb5af054UL, 0x3ad2351100f322d5UL, 0x24a21f70f0b14613UL,
      0x475dbafc509421a2UL, 0x9e78abd3cd79162cUL, 0xe492fd5185f74274UL,
      0xc974fffbb9c5bcbdUL, 0x2fdc971bd1756a88UL, 0x7229f20d9ed56e61UL,
      0x724bb3259de1f22fUL, 0xebdba47c4a9c567aUL, 0xf93c634904fe151aUL,
      0x051bcfecd0485d42UL, 0x94974a65ffaf78a4UL, 0x1e2e5e3f8b50a25dUL,
      0x81b99d563b25e57aUL, 0xdae46bb9fceadb75UL, 0xde35e8171244a7b5UL,
      0xf4fc75ad58cca9f2UL, 0x06396ddce8fd9c68UL, 0x9acabf60af793fb6UL,
      0x5329b615e95c5bdfUL, 0xd86f5fd82254a62fUL, 0xf0af6c56a32479b2UL,
      0xca21baeeba56a815UL, 0x0396c3624ca42a50UL, 0xaccae9419d0f493fUL,
      0x6d148daab4ac1bb7UL, 0xdbd78e8efc177ba2UL, 0xcee72e2a4d16dcc6UL,
      0x4590974f7d6ec962UL, 0xd3b28408305b5764UL, 0x20c201d44df1eb89UL,
      0x0cef72d2cdef5930UL, 0xa9e4ca60ebc9a62aUL, 0x8f84dab7d30110cdUL,
      0x6803ad1d2c809a22UL, 0x4e3319dcbeefdd75UL, 0xb1c8fe5b88eaedbbUL,
      0x3d5ceaecade87f00UL ],
    [ 0xdb87073201334b8eUL, 0x5a37d087e1ae272bUL, 0x80b67cc99b9d27a1UL,
      0xd09d5f7db214f4baUL, 0x3306a98928d65742UL, 0x65bc1cc4ac254147UL,
      0x92e266c8e0c61bd7UL, 0x3efe1a6dd93a7ea9UL, 0x516008fcc74b5982UL,
      0x7087c00b1219938aUL, 0x54ed780d615a4d93UL, 0xf7b393019e97eb56UL,
      0x282b3182cb55067cUL, 0xf74719c6e544ea8dUL, 0x35629880486810e2UL,
      0xccb4db1f1f298264UL, 0x801d864f04ade5d0UL, 0xe32ae6267b0c6f71UL,
      0xc33dbe2c2656b326UL, 0x8cf005f6aced02b1UL, 0x1f4f622ce80d5b56UL,
      0x5c5166351f09065cUL, 0x27ee88da0b3f17f3UL, 0x24342d232e1cc60dUL,
      0xe71b0ef73358b399UL, 0x8032078133780469UL, 0xe34b1780fa310f3dUL,
      0xcde826ad5c866d50UL, 0x61cbad7ae034ed02UL, 0x7ec80dc7d5443ff8UL,
      0x7552b2e6a70d2fefUL, 0xb5c65d387d8a622eUL, 0xcb74a3731b1404dfUL,
      0x3d17820c84c52320UL, 0x012907839e217ebbUL, 0xeb7f86a56d1ae07aUL,
      0xf934a28184b8bc95UL, 0xe18c5514a3ffc474UL, 0x81e302d64f1e874aUL,
      0x993d2d29543a0051UL, 0x4710980708601e84UL, 0xc7301ea9cc8b59beUL,
      0x947c354adc6fc86fUL, 0xba7443084a3f3d4dUL, 0x468112e49b318b2eUL,
      0x636e353267f00946UL, 0xae160a34615f3ce7UL, 0xd38ce1fbfa0ae670UL,
      0x183da8dda4081ec1UL, 0xeccb6d0700512aa9UL, 0xafffc8e3770d1024UL,
      0xcc95e0c2786e2d74UL, 0x7a889c70ef7b2d7bUL, 0xc1612de64cbd613fUL,
      0xf102a29abfbadfefUL, 0x9aa9300a182763faUL, 0x1bc552dcfcfd38a8UL,
      0x0a7b6521e6b8170dUL, 0x2ba06c62d6b1efcdUL, 0xeea0e6daafd143a8UL,
      0x9d02cbfd6f7cc234UL, 0x8aecebc23d68acb5UL, 0x1d1aa95d783617a7UL,
      0x514e9d5763edb419UL ],
    [ 0x1e8860e4e8afcffcUL, 0x107fb5302e49b653UL, 0x453ca2eb419de2c5UL,
      0xa3094e8eb1649123UL, 0xe850ac9a440dd0afUL, 0xe6eb2d90ade835b6UL,
      0x75dfa9af6b2e2517UL, 0x89d272086a4586b0UL, 0x04f2d543b5fdd518UL,
      0xec4c28a9a0d6e1e7UL, 0x17258fcd264c21dbUL, 0xf556bc18377a9614UL,
      0x1ed98b8d00ed78d9UL, 0x878cc5541b15235aUL, 0xbdaad05ff19daba8UL,
      0x92847c097dfa71e5UL, 0x350e0dd9be966d1fUL, 0xa6a60d7f6f49639cUL,
      0x8e070da95c30c7b1UL, 0x86cfaab004eeb6baUL, 0xebaaec50d1c327f4UL,
      0xc2fe1876ab524708UL, 0xc6f6d37551ec8e3dUL, 0x64d37e4c261b7ceeUL,
      0x5c4238429df044d6UL, 0xffc2dcfba6020f1cUL, 0x219884780eb85505UL,
      0x7b344c05cf490f3cUL, 0x6357c42cdd1ece03UL, 0xe843f0447fc918ccUL,
      0x3f6b9ecca16d6a9cUL, 0xcadd7b5fa7f80548UL, 0x99932206ba13d48eUL,
      0x2e2c3d8d923d7498UL, 0x313c5a25c7cc37ecUL, 0x1ad15364afedeef6UL,
      0xfd191a29a2e31a19UL, 0x260efed6924e37c5UL, 0x59131a8c25dde4d2UL,
      0x7c21c4dec49fcb54UL, 0x7e6ce786fbf85990UL, 0xd9e19bec0755de20UL,
      0xbd6610b15f183afbUL, 0x8973e87e3a7c8151UL, 0x08dc85a2ef21e267UL,
      0x8a5d053e38e38217UL, 0x362b10df55d34595UL, 0xec947b5836bd99a6UL,
      0xa86b61318e8e0669UL, 0x77fb8d13554c503bUL, 0x7f2e977aecd4b847UL,
      0x1a1209b4297349a0UL, 0x246ef6a2583a91d2UL, 0xe899f0f10718bb1bUL,
      0x8caf1fed80b0bf73UL, 0x6692b681b5b0cd56UL, 0x88a59e6e5279a693UL,
      0x2bca6fda2127725bUL, 0xde231627953ee461UL, 0xa6a84fe6019b1505UL,
      0x3aa8d5c92821286fUL, 0x3fc7c4ff83788dc8UL, 0x2f1c86701e11126cUL,
      0xbcf523cd44449d04UL ],
    [ 0xb6bd2e675553abfbUL, 0x0e77d5c32d27b9f1UL, 0x514eeb41d9c3d9ffUL,
      0x628b101131d29234UL, 0x8ffb7c8ed0e68e19UL, 0x8ae2aad5fb090e47UL,
      0x189f977852a4f512UL, 0x95ca324d8b0efd83UL, 0x738c57e030fdae11UL,
      0x959b0a940dd59306UL, 0x65da2016543c234bUL, 0x4b832a3630d9185cUL,
      0x0c097ea2fdbf0d2cUL, 0xfb4c8e0aa5234704UL, 0x7ac234e158f27179UL,
      0xbac5a1e34be49be8UL, 0x971437a9f55584bbUL, 0x0b936a48e3a2ff38UL,
      0xce5064cedf5414ffUL, 0xe843d8e0f1a1b404UL, 0x94b3ca3bb9a34c7fUL,
      0x2ad9eef539a002e0UL, 0x6775351b325f3972UL, 0x73a452a5d7816842UL,
      0x8f820c6a3867e2f5UL, 0x195da076e4eb0c03UL, 0xbf06d1e5880ef7e9UL,
      0x10194dde08d9bfb5UL, 0xc43bf19aac12b322UL, 0xe5574447f21ad4fbUL,
      0x0022f70230a30040UL, 0xb92a66f9542cc415UL, 0x8fbcd882499ec90dUL,
      0x7d7ee407c482adb5UL, 0xf284329e4afed0eaUL, 0xa4a200b66d4b9a8fUL,
      0x9d579f70abf43ad5UL, 0x6d99c3c17a861697UL, 0xefdfea41ede917ffUL,
      0x0dd85b0a545ce9ebUL, 0x695f389eb81c31c4UL, 0x3e49b5c0ed676305UL,
      0x4c0792eaab653521UL, 0xae7febb40ef265f8UL, 0x735fd7bae0b300b6UL,
      0x5cd2f906d01617fdUL, 0xe425e6a2194f35b8UL, 0x5e454d35558f736fUL,
      0xd6f7a25040a80510UL, 0x9ff8fd33a560058cUL, 0xc7615283555e4d1aUL,
      0x46403dffc8013c90UL, 0x4e4a44a1479e3e2eUL, 0xc658ada906c5037bUL,
      0x54e1529f6a6c0706UL, 0x5a929ed61f0bb3d6UL, 0x657aacb5a4eef250UL,
      0x8d75f946b56d5c44UL, 0x3852aab719722cbaUL, 0xa7e416420eb9da68UL,
      0x9b7a5005d064dd92UL, 0xeaf7ce1d22dee993UL, 0x34aced1247e27fb8UL,
      0xf23478d46ca33d46UL ]],
   [[ 0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL ],
    [ 0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x6b90680243c4b54cUL,
      0x044703d57fb1e299UL, 0x8a3c60812c08665aUL, 0x32dc7de4cae88a7bUL,
      0x6e3060c4bbed7feeUL, 0x09a012c21457c46fUL, 0x713f791a21ad43caUL,
      0x5a4d0ec873244cdfUL, 0x59a713355c986f8fUL, 0xa347356dba0fbfadUL,
      0x6650c485ba5b1243UL, 0x2d86094817cc64f2UL, 0x20fdc446a93f6201UL,
      0x1db9308f0d27dbdfUL, 0x98f63ae9645b1111UL, 0x03415b7672cca0bdUL,
      0x910f4a575767cff3UL, 0x5182927aff4f928cUL, 0xdde2b660565a30dcUL,
      0x3f42ec666558c5b3UL, 0xce05da712568cac7UL, 0xfd9326b46e518555UL,
      0x9334d36563994ecdUL, 0x3bd434362a7b358cUL, 0x14b4d64afc2171bbUL,
      0x8332f03346030a46UL, 0x56300105aba021c0UL, 0x470610c2fb63b7b5UL,
      0x10c12cf0c2f837f5UL, 0x7d8af8d403969661UL, 0xa8cb40dbe096915dUL,
      0xfb306c5498354397UL, 0xe25d9ee093992b8bUL, 0x1f406a7e77f19817UL,
      0x06592044d4d8c7e7UL, 0x986ca3c584c84454UL, 0xcec495f755c884f0UL,
      0x3d8e0276e94a3fb3UL, 0x6dfc65f711f0e645UL, 0xf04572c328e9c0fdUL,
      0x1de908cfe3f5fc3bUL, 0xe1e609e5214fc6f0UL, 0x1b97e198798ccc46UL,
      0x52983c479b769f0dUL, 0xe1ad316c24a875e2UL, 0x759a9b5ac9742a91UL,
      0x6bb1e5f7b2bb7e47UL, 0xbdd56e8cc40b30baUL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
      0x0000000000000000UL ],
    [ 0xe543c7cd3569a2d2UL, 0x56312cb746ff2365UL, 0x03e7298e5b86bf22UL,
      0x516e9a17bf3b9d0eUL, 0xb507b363062bfe41UL, 0x7600192a061dd0e5UL,
      0x1d3fdfd7ab7ed9eeUL, 0x422f696efd2a98f8UL, 0x4d3652c8c76f687cUL,
      0x9f7711eae210b999UL, 0x3fe55a4a3db93342UL, 0xf9867077d2c22292UL,
      0x06938ebd5352aba1UL, 0xcfbdf8fd28e52d4aUL, 0x9f5dc89b771ea0baUL,
      0x76170ff911d3d955UL, 0x7e7bddf4e7d92fadUL, 0x28bb97717bb86c3fUL,
      0xe14b10911730bfe5UL, 0x65fdc8cfbb000784UL, 0x3413b92f048583c8UL,
      0x449ccb9483380adcUL, 0xa4a34f7dd630cec5UL, 0xf23142fcbf290710UL,
      0xab1645e0b73ebeb6UL, 0x9f7ac648b66b58efUL, 0x81da786a8e1a3a07UL,
      0xab80b2cb27644d91UL, 0xc57b0159cd1cf77aUL, 0x84425693d1e998f6UL,
      0xa086ad9f1b17e973UL, 0x6c29c7100c6ea19bUL, 0x3a318a14b98d372bUL,
      0xf01ba582f9382406UL, 0xa1cde875f370ae9cUL, 0xb9a0ab780158707eUL,
      0x8d26ff790475117eUL, 0xdd33f98a55e26ad9UL, 0x549c9afccdff9451UL,
      0xfed35e6c20eabe08UL, 0xee602ea3d3b08637UL, 0xfb60f74da1a791f3UL,
      0xb25a86f4ba75b20eUL, 0x5402f6bd8285b194UL, 0xb5e9f6533809151fUL,
      0x074c656721f3bb77UL, 0x5ccdeff9d4bbbf2dUL, 0xbe262f406756394dUL,
      0x105f0a553888caadUL, 0xb364c84f9a7f366dUL, 0x13c5a20c72a2e3ceUL,
      0xb6121d22131c0104UL, 0xa4cb87927ec6cc17UL, 0x897b31544122583bUL,
      0xd9bed4853c502a78UL, 0x211fee372e06645fUL, 0x87d38f49fd841678UL,
      0x22644edaa636120aUL, 0x693c919475426cccUL, 0x77b3666bd380005dUL,
      0x09972e5b72ba54c1UL, 0xa6d576eb8a9adbefUL, 0x151e128a1470cc43UL,
      0xba872ea0ccbcac7cUL ],
    [ 0xfaadf26b0bedcb90UL, 0x577ac5a51e5651c5UL, 0xfaa9928d90ecc574UL,
      0xf4d0746e2cd9c2cbUL, 0x297b213cebe4451bUL, 0xdcda00e8a1970957UL,
      0xebc24328279cf3c0UL, 0xafbc7b8a2782f71aUL, 0x2b8ae9d228a44b14UL,
      0x7b91361891e74156UL, 0x7c744bd7713ebc3cUL, 0xf30ff94d8ae2dbbcUL,
      0x952d28d81c4cd5e5UL, 0xca1da973d1bb1a14UL, 0x0dc59391a4b26780UL,
      0x73974085e2ebdfedUL, 0x6a9d797790afccadUL, 0x192a2b602b123aabUL,
      0x19c8a787015bc845UL, 0xad40920248a2e551UL, 0xd1c0fbdcb077da5dUL,
      0xf0d3a2e4b44b9030UL, 0x4ff44c34da7b4dd0UL, 0x65ca4e0e02964227UL,
      0x1fc804c725e40440UL, 0xde8e75b6789090ffUL, 0xda82400db9d07a0aUL,
      0x7f850c159d730e8dUL, 0x88f3cb3c8b5dbf18UL, 0xaa16f0d4828d0050UL,
      0x46a26a52fc055ad2UL, 0x9924d71d3d7359bfUL, 0x73580533d9f2fb99UL,
      0x187096a491259118UL, 0x7777434ec63d90f8UL, 0x8e6e9922b252bdb1UL,
      0xb1af461d516eee12UL, 0x4fcd31f2f421c717UL, 0x65651bc93644c5e1UL,
      0x9bd1e1fa908307daUL, 0x5aaee550208ae7f0UL, 0x4ec958544caaa9c3UL,
      0x298e4a3f09caee63UL, 0x29d4a3cab10a9a44UL, 0x9e6a3fde44907510UL,
      0x19cc5ee9aa4fbc78UL, 0xc01a289fe006387fUL, 0x3ee6737f5f934fb3UL,
      0x65fad64d232fe9eeUL, 0x2a487fc2e4f569fbUL, 0x67fb5df086391215UL,
      0xc1b5e63af64d55e8UL, 0xd33f764f4052ecb7UL, 0x0899d25e2b391f79UL,
      0xc70158cce44d2e70UL, 0xb53262e2308fa659UL, 0x20f7402ecd84404cUL,
      0x15d1b9bb5466ad4cUL, 0xfd8d825e26a8a2d1UL, 0x18d96f18f8b826d0UL,
      0xf72067659687ef21UL, 0xf08610bafd66009fUL, 0x1a4e1ba1fdb05563UL,
      0x1324d44c84bbef0aUL ],
    [ 0xc7613d66f20232d4UL, 0x3ede983f7b06516bUL, 0x578460a649b24a39UL,
      0xd5bd4ad2cc618853UL, 0x6da1e9f12833259cUL, 0x1f9ca81ea33005a0UL,
      0xae981ca25036ed10UL, 0x5d69e428228cca9aUL, 0xa17023dd34f22effUL,
      0xd08c493917325f88UL, 0x79e16b54bdca7e02UL, 0x3654be3ac3a26289UL,
      0xac56a76157fd0921UL, 0xc517aa54a54ed12dUL, 0x4dd1b68eb1ada829UL,
      0x161037898e176e8dUL, 0x98db096afb729bebUL, 0x03e9d68eabc9d7feUL,
      0xdf27c2fb173845dcUL, 0x2aee2474d7bf2d7cUL, 0xf5d6d12955e96f2dUL,
      0xf734ec0a2d041943UL, 0x72999224bb580060UL, 0xccdcad5bdc7bd1a1UL,
      0xa9bca8004f1d7086UL, 0xc2c7ffb795d4e1e7UL, 0xd28da598cbfbc3caUL,
      0x08126a5da13c42d9UL, 0x13e15ad5c2d3d951UL, 0x4d9c20c7eaa8703dUL,
      0xab894b4e6ebca682UL, 0x53214a10ad7c784eUL, 0x9906d6c9c38b591eUL,
      0x476bd91a4ca0c161UL, 0x95265cbe69f01d02UL, 0x01cedc5a39e5b5c9UL,
      0xc0ef0788f08d9463UL, 0x80927db966612b20UL, 0x9630082145dd2f1eUL,
      0x600f737ed7910113UL, 0xb9302c026f2a80b2UL, 0xff49c8f0afc01a91UL,
      0x39a0b9dbbc8e5d10UL, 0x4e93e5fbc38cafd7UL, 0x44d0aec75c666288UL,
      0x5ea41ef6508a97efUL, 0x6ce58a3a4917dffdUL, 0x57b84b8764d3da3dUL,
      0xedf320cbe664658cUL, 0x3bea7e195d96172aUL, 0x72abd9c2b876c142UL,
      0xaf2ce404a46dae6eUL, 0x4f050de918e728b2UL, 0xcb458cba72881a48UL,
      0xdadcfcb48f1c02a8UL, 0x1167bf4ccb9f1a34UL, 0x2f791f047047bd5dUL,
      0xcd60c5789e26b8b6UL, 0x1a620288f4a12b4bUL, 0x1b43a4a5b7f5244dUL,
      0x3a93e22c7f6b3c55UL, 0xa5da9b1ba501f044UL, 0xac918f8b4d9d1e00UL,
      0x9fba7867a63c8ac8UL ],
    [ 0xb5663909d9d6303aUL, 0x1122bbd8f31a9801UL, 0xb26dfdc7254c0ac9UL,
      0x80923ffe2bae8db2UL, 0xdf3939952977e95fUL, 0x89ef22889d7081a6UL,
      0xddeeb25f2e41e526UL, 0x77aa072d06890a48UL, 0x8b1e7a1bc43beb1cUL,
      0xeef27b1803a60f3aUL, 0x116569c8ba82a83aUL, 0x861eddf3fdf4d64fUL,
      0x12fc5033c7c95105UL, 0xc9997d1a2f05161aUL, 0x56dbac3597f7e48bUL,
      0x997968b0dadb71b6UL, 0x51c153dd787cf748UL, 0x190b253068b60e60UL,
      0xa98dcc93091ee1daUL, 0xe7f1c48a17f0c994UL, 0x294532d1f3b50a20UL,
      0xe393a663d106d4b2UL, 0xc95a8e15d4e4aac2UL, 0x058a1a4819387af4UL,
      0xb7fe4077025d3331UL, 0x17369b1ad4dfb135UL, 0xfd1836fd44897416UL,
      0x734f98ea7a95ea1dUL, 0x44dbebde2de33051UL, 0x3e572ff979d8ca38UL,
      0xd53c5a45bb8cdfa1UL, 0x1169ade998830992UL, 0xc6b5b477d2ee43b5UL,
      0x11d58b895af5f73aUL, 0xcfe3985db2d35d21UL, 0xc9c6056490e28221UL,
      0xbba44fb18d7bad4cUL, 0xd1b94354c3d22c4dUL, 0xfb0d0d4c55eedddeUL,
      0x3b18e9ef00b4c810UL, 0x73e101f840df8084UL, 0xd64f148443724752UL,
      0xb017cbfb12688bd6UL, 0x89e6a53131fc7242UL, 0x2f6bc2d724af9792UL,
      0x1af46d6374011c6aUL, 0xe7d461f15c6129b4UL, 0xbd7b0f8478d446abUL,
      0x8cab2463b6c0e01dUL, 0xa69dee16a765d2b0UL, 0x144588401f496bf3UL,
      0x3d761d20063ee258UL, 0x48c0b32df8ddc0fbUL, 0x1ad8889a5aa8e26cUL,
      0x2aadb6180f80c2d3UL, 0xb7c9d582a54c0b2cUL, 0xa9448d0f698b8370UL,
      0xd6814d04b2584c63UL, 0x80576b83319d83f9UL, 0x906953398a3df494UL,
      0xe7a11b9d7d769494UL, 0x59714b37b93b5e39UL, 0xa5280a61ef2d0450UL,
      0xcaf1ca6cd004e7bcUL ],
    [ 0x0c92df7ab48210acUL, 0x70c766782c6225c0UL, 0x2b627e280a8dd01fUL,
      0xf8a95606e064f51bUL, 0xecb6d461dd6c8568UL, 0xe8e9d8da88a760e7UL,
      0xb253ddc5e1b54ff4UL, 0xb518eacb142499c5UL, 0x5ba23807ace2576bUL,
      0xb5d274ebd42fcb9cUL, 0x1dfc510cd7016641UL, 0x81b2aa898d7ff740UL,
      0xb3f8b22a412d350fUL, 0x9010d26bd30013d6UL, 0x31a160801ed3585fUL,
      0xf18717011ddb123bUL, 0x475fb6cd262d3895UL, 0xf86a9bada37fe981UL,
      0x579fe8f10c63060cUL, 0x1ea46e3bcbee6f47UL, 0x0dfa846a5626e47aUL,
      0xe76ff8e4aab118a0UL, 0xa83a45a05758d1c4UL, 0xff293f1d1de94a79UL,
      0x6d34106328ce50acUL, 0x7f3dd6bb2c715f0dUL, 0x01a6483cc3fb62c0UL,
      0xa60927ade8ccdca7UL, 0x73c1dc8d32c0180fUL, 0x02f86bcc14474ff9UL,
      0x3804de0c37c58434UL, 0xfc10f3a3c497c54dUL, 0x96a1e55142ddb8dbUL,
      0xc92548d8939af17aUL, 0xbc5edf6509acaf89UL, 0xac0b9688d3023544UL,
      0x4163dbff847088b3UL, 0x563f3cfce243d3f8UL, 0x8f263f7ce1f7b3ccUL,
      0xe7365cbc6a7f8730UL, 0x46c1f063e6b8ca39UL, 0x21cbc42ba4582264UL,
      0x55dff0476966e4b4UL, 0x223e2c38b61edc4eUL, 0x3a21ced28a3d6fa8UL,
      0xd5884ee48c058d27UL, 0x884d4eac614c987aUL, 0x02327b02f1a6a37fUL,
      0xec14f49f926b0d1dUL, 0xad980ec0c9b3ccdcUL, 0xad0f89f58a31f96cUL,
      0x1004ad6869a8c64dUL, 0x73334f7053ecda9cUL, 0xe5c726eb2395f91fUL,
      0x3eacccee6b0d2cf0UL, 0x54fe44475c2803fbUL, 0x4e691ecbfdff4c35UL,
      0x0d4dd3188efdf8f3UL, 0x4ce513f999517686UL, 0x451033ddedb79722UL,
      0x7fafe619290cf26eUL, 0xb744be4992d915b4UL, 0x8011bf394690d8d1UL,
      0x9475361b15b45cd5UL ],
  ],
];
ulong castle_random[2][2] = [
  [ 0x557723689550b69bUL, 0xa92c541efa336c6cUL ],
  [ 0xc7bedab779d5361bUL, 0x3bb70e80435e60b7UL ]

];
ulong enpassant_random[65] = [
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0xf2c1412f44c13c98UL, 0x76b4b7ccb0c9bd1eUL,
  0x0303f047ef3166cdUL, 0xcf4da3850ff5c35aUL, 0x0bb57340632ec140UL,
  0x189156c368616498UL, 0x71b862b8cede277dUL, 0x26e0433817e6d7d7UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x1f2af0448165ab3aUL, 0x51f0d423276d44dbUL,
  0x12d51a6ba742f661UL, 0x8fa3e91c53630e1fUL, 0x16573a4eb7f48c08UL,
  0xe1c1e4bc9690e409UL, 0x5f2bf4422dde33bbUL, 0xcd4cefba64f407a1UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL, 0x0000000000000000UL,
  0x0000000000000000UL, 0x0000000000000000UL
];


/*
 *******************************************************************************
 *                                                                             *
 *  A 32 bit random number generator. An implementation in C of the algorithm  *
 *  given by Knuth, the art of computer programming, vol. 2, pp. 26-27. We use *
 *  e=32, so we have to evaluate y(n) = y(n - 24) + y(n - 55) mod 2^32, which  *
 *  is implicitly done by unsigned arithmetic.                                 *
 *                                                                             *
 *******************************************************************************
 */
//uint Random32() {
/*
 random numbers from Mathematica 2.0.
 SeedRandom = 1;
 Table[Random[Integer, {0, 2^32 - 1}]
 */
/* 
  static const ulong x[55] = [
    1410651636UL, 3012776752UL, 3497475623UL, 2892145026UL, 1571949714UL,
    3253082284UL, 3489895018UL, 387949491UL, 2597396737UL, 1981903553UL,
    3160251843UL, 129444464UL, 1851443344UL, 4156445905UL, 224604922UL,
    1455067070UL, 3953493484UL, 1460937157UL, 2528362617UL, 317430674UL,
    3229354360UL, 117491133UL, 832845075UL, 1961600170UL, 1321557429UL,
    747750121UL, 545747446UL, 810476036UL, 503334515UL, 4088144633UL,
    2824216555UL, 3738252341UL, 3493754131UL, 3672533954UL, 29494241UL,
    1180928407UL, 4213624418UL, 33062851UL, 3221315737UL, 1145213552UL,
    2957984897UL, 4078668503UL, 2262661702UL, 65478801UL, 2527208841UL,
    1960622036UL, 315685891UL, 1196037864UL, 804614524UL, 1421733266UL,
    2017105031UL, 3882325900UL, 810735053UL, 384606609UL, 2393861397UL
  ];
  static int init = 1;
  static ulong y[55];
  static int j, k;
  ulong ul;

  if (init) {
    int i;

    init = 0;
    for (i = 0; i < 55; i++)
      y[i] = x[i];
    j = 24 - 1;
    k = 55 - 1;
  }
  ul = (y[k] += y[j]);
  if (--j < 0)
    j = 55 - 1;
  if (--k < 0)
    k = 55 - 1;
  return (to!uint(ul));
}
*/
/*
 *******************************************************************************
 *                                                                             *
 *   Random64() uses two calls to Random32() and then concatenates the two     *
 *   values into one 64 bit random number, used for hash signature updates on  *
 *   the Zobrist hash signatures.                                              *
 *                                                                             *
 *******************************************************************************
 */
/* 
ulong Random64() {
  ulong result;
  uint r1, r2;

  r1 = Random32();
  r2 = Random32();
  result = r1 | to!ulong(r2) << 32;
  return (result);
}
*/
void HashStore(ref Tree tree, int ply, int depth, int wtm, int type, int value, int bestmove) {
  Hash_Entry* htable;
  Hash_Entry* replace;
  Hpath_Entry* ptable;
  ulong word1, temp_hashkey;
  int entry, draft, age, replace_draft, i, j;

/*
 ************************************************************
 *                                                          *
 *   "Fill in the blank" and build a table entry from       *
 *   current search information.                            *
 *                                                          *
 ************************************************************
 */
  word1 = transposition_age;
  word1 = (word1 << 2) | type;
  if (value > MATE - 300)
    value += ply - 1;
  else if (value < -MATE + 300)
    value -= ply - 1;
  word1 = (word1 << 21) | bestmove;
  word1 = (word1 << 15) | depth;
  word1 = (word1 << 17) | (value + 65536);
  temp_hashkey = (wtm) ? tree.p.hash_key : ~tree.p.hash_key;
/*
 ************************************************************
 *                                                          *
 *   Now we search for an entry to overwrite in three       *
 *   passes.                                                *
 *                                                          *
 *   Pass 1:  If any signature in the table matches the     *
 *     current signature, we are going to overwrite this    *
 *     entry, period.  It might seem worthwhile to check    *
 *     the draft and not overwrite if the table draft is    *
 *     greater than the current remaining depth, but after  *
 *     you think about it, this is a bad idea.  If the      *
 *     draft is greater than or equal the current remaining *
 *     depth, then we should never get here unless the      *
 *     stored bound or score is unusable because of the     *
 *     current alpha/beta window.  So we are overwriting to *
 *     avoid losing the current result.                     *
 *                                                          *
 *   Pass 2:  If any of the entries come from a previous    *
 *     search (not iteration) then we choose the entry from *
 *     this set that has the smallest draft, since it is    *
 *     the least potentially usable result.                 *
 *                                                          *
 *   Pass 3:  If neither of the above two found an entry to *
 *     overwrite, we simply choose the entry from the       *
 *     bucket with the smallest draft and overwrite that.   *
 *                                                          *
 ************************************************************
 */
  htable = trans_ref + (temp_hashkey & hash_mask);
  for (entry = 0; entry < 4; entry++, htable++) {
    if (temp_hashkey == (htable.word1 ^ htable.word2)) {
      replace = htable;
      break;
    }
  }
  if (!replace) {
    replace_draft = 99999;
    htable = trans_ref + (temp_hashkey & hash_mask);
    for (entry = 0; entry < 4; entry++, htable++) {
      age = htable.word1 >> 55;
      draft = (htable.word1 >> 17) & 0x7fff;
      if (age != transposition_age && replace_draft > draft) {
        replace = htable;
        replace_draft = draft;
      }
    }
    if (!replace) {
      htable = trans_ref + (temp_hashkey & hash_mask);
      for (entry = 0; entry < 4; entry++, htable++) {
        draft = (htable.word1 >> 17) & 0x7fff;
        if (replace_draft > draft) {
          replace = htable;
          replace_draft = draft;
        }
      }
    }
  }
/*
 ************************************************************
 *                                                          *
 *   Now that we know which entry to replace, we simply     *
 *   stuff the values and exit.  Note that the two 64 bit   *
 *   words are xor'ed together and stored as the signature  *
 *   for the "lockless-hash" approach.                      *
 *                                                          *
 ************************************************************
 */
  replace.word1 = word1;
  replace.word2 = temp_hashkey ^ word1;
/*
 ************************************************************
 *                                                          *
 *   If this is an EXACT entry, we are going to store the   *
 *   PV in a safe place so that if we get a hit on this     *
 *   entry, we can recover the PV and see the complete path *
 *   rather than one that is incomplete.                    *
 *                                                          *
 ************************************************************
 */
 
  if (type == EXACT) {
    ptable = hash_path + (temp_hashkey & hash_path_mask);
    for (i = 0; i < 16; i++, ptable++) {
      if (ptable.path_sig == temp_hashkey ||
          ((transposition_age - ptable.hash_path_age) > 1)) {
        for (j = ply; j < tree.pv[ply - 1].pathl; j++)
          ptable.hash_path_moves[j - ply] = tree.pv[ply - 1].path[j];
        ptable.hash_pathl = tree.pv[ply - 1].pathl - ply;
        ptable.path_sig = temp_hashkey;
        ptable.hash_path_age = transposition_age;
        break;
      }
    }
  }
  
}

int HashProbe(ref Tree tree, int ply, int depth, int wtm, int alpha,int beta, ref int value) {
  Hash_Entry* htable;
  Hpath_Entry* ptable;
  ulong word1, word2, temp_hashkey;
  int type, draft, avoid_null = 0, val, entry, i, j;

/*
 ************************************************************
 *                                                          *
 *   All we have to do is loop through four entries to see  *
 *   there is a signature match.  There can only be one     *
 *   instance of any single signature, so the first match   *
 *   is all we need.                                        *
 *                                                          *
 ************************************************************
 */
  //tree->hash_move[ply] = 0;
  temp_hashkey = (wtm) ? tree.p.hash_key : ~tree.p.hash_key;
  htable = trans_ref + (temp_hashkey & hash_mask);
  for (entry = 0; entry < 4; entry++, htable++) {
    word1 = htable.word1;
    word2 = htable.word2 ^ word1;
    if (word2 == temp_hashkey)
      break;
  }
/*
 ************************************************************
 *                                                          *
 *   If we found a match, we have to verify that the draft  *
 *   is at least equal to the current depth, if not higher, *
 *   and that the bound/score will let us terminate the     *
 *   search early.                                          *
 *                                                          *
 *   We also return an "avoid_null" status if the matched   *
 *   entry does not have enough draft to terminate the      *
 *   current search but does have enough draft to prove     *
 *   that a null-move search would not fail high.  This     *
 *   avoids the null-move search overhead in positions      *
 *   where it is simply a waste of time to try it.          *
 *                                                          *
 *   If this is an EXACT entry, we are going to store the   *
 *   PV in a safe place so that if we get a hit on this     *
 *   entry, we can recover the PV and see the complete path *
 *   rather than one that is incomplete.                    *
 *                                                          *
 *   One other issue is to update the age field if we get a *
 *   hit on an old position, so that it won't be replaced   *
 *   just because it came from a previous search.           *
 *                                                          *
 ************************************************************
 */
  if (entry < 4) {
    if (word1 >> 55 != transposition_age) {
      word1 =
          (word1 & 0x007fffffffffffffUL) | (to!ulong(transposition_age) << 55);
      htable.word1 = word1;
      htable.word2 = word1 ^ word2;
    }
    val = (to!int(word1 & 0x1ffff) - 65536);
    draft = (word1 >> 17) & 0x7fff;
    tree.hash_move[ply] = (word1 >> 32) & 0x1fffff;
    type = (word1 >> 53) & 3;
    if ((type & UPPER) && depth - null_depth - 1 <= draft && val < beta)
      avoid_null = AVOID_NULL_MOVE;
    if (depth <= draft) {
      if (val > MATE - 300)
        val -= ply - 1;
      else if (val < -MATE + 300)
        val += ply - 1;
      value = val;
/*
 ************************************************************
 *                                                          *
 *   We have three types of results.  An EXACT entry was    *
 *   stored when val > alpha and val < beta, and represents *
 *   an exact score.  An UPPER entry was stored when val <  *
 *   alpha, which represents an upper bound with the score  *
 *   likely being even lower.  A LOWER entry was stored     *
 *   when val > beta, which represents alower bound with    *
 *   the score likely being even higher.                    *
 *                                                          *
 *   For EXACT entries, we save the path from the position  *
 *   to the terminal node that produced the backed-up score *
 *   so that we can complete the PV if we get a hash hit on *
 *   this entry.                                            *
 *                                                          *
 ************************************************************
 */
      switch (type) {
        case EXACT:
          if (val > alpha && val < beta) {
            SavePV(tree, ply, 1 + (draft == MAX_DRAFT));
            ptable = hash_path + (temp_hashkey & hash_path_mask);
            for (i = 0; i < 16; i++, ptable++)
              if (ptable.path_sig == temp_hashkey) {
                for (j = ply; j < min(MAXPLY - 1, ptable.hash_pathl + ply); j++)
                  tree.pv[ply - 1].path[j] = ptable.hash_path_moves[j - ply];
                if (draft != MAX_DRAFT && ptable.hash_pathl + ply < MAXPLY - 1)
                  tree.pv[ply - 1].pathh = 0;
                tree.pv[ply - 1].pathl = to!ubyte(min(MAXPLY - 1, ply + ptable.hash_pathl));
                ptable.hash_path_age = transposition_age;
                break;
              }
          }
          return (HASH_HIT);
        case UPPER:
          if (val <= alpha)
            return (HASH_HIT);
          break;
        case LOWER:
          if (val >= beta)
            return (HASH_HIT);
          break;
        default:
          break;
      }
    }
    return (avoid_null);
  }
  return (HASH_MISS);
}


