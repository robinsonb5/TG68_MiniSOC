library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Hex_ROM is
generic
	(
		maxAddrBitBRAM : integer := 15 -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
	);
port (
	clk : in std_logic;
	reset_n : in std_logic := '1';
	addr : in std_logic_vector(maxAddrBitBRAM downto 0);
	q : out std_logic_vector(15 downto 0);
	-- Allow writes - defaults supplied to simplify projects that don't need to write.
	d : in std_logic_vector(15 downto 0) := X"0000";
	we_n : in std_logic := '1';
	uds_n : in std_logic := '1';
	lds_n : in std_logic := '1'
);
end Hex_ROM;

architecture arch of Hex_ROM is

type ram_type is array(natural range 0 to (2**(maxAddrBitBRAM+1)-1)) of std_logic_vector(7 downto 0);

shared variable ram : ram_type :=
(
     0 => x"00",
     1 => x"00",
     2 => x"0f",
     3 => x"fe",
     4 => x"00",
     5 => x"00",
     6 => x"01",
     7 => x"00",
     8 => x"00",
     9 => x"00",
    10 => x"00",
    11 => x"00",
    12 => x"00",
    13 => x"00",
    14 => x"00",
    15 => x"00",
    16 => x"00",
    17 => x"00",
    18 => x"00",
    19 => x"00",
    20 => x"00",
    21 => x"00",
    22 => x"00",
    23 => x"00",
    24 => x"00",
    25 => x"00",
    26 => x"00",
    27 => x"00",
    28 => x"00",
    29 => x"00",
    30 => x"00",
    31 => x"00",
    32 => x"00",
    33 => x"00",
    34 => x"00",
    35 => x"00",
    36 => x"00",
    37 => x"00",
    38 => x"00",
    39 => x"00",
    40 => x"00",
    41 => x"00",
    42 => x"00",
    43 => x"00",
    44 => x"00",
    45 => x"00",
    46 => x"00",
    47 => x"00",
    48 => x"00",
    49 => x"00",
    50 => x"00",
    51 => x"00",
    52 => x"00",
    53 => x"00",
    54 => x"00",
    55 => x"00",
    56 => x"00",
    57 => x"00",
    58 => x"00",
    59 => x"00",
    60 => x"00",
    61 => x"00",
    62 => x"00",
    63 => x"00",
    64 => x"00",
    65 => x"00",
    66 => x"00",
    67 => x"00",
    68 => x"00",
    69 => x"00",
    70 => x"00",
    71 => x"00",
    72 => x"00",
    73 => x"00",
    74 => x"00",
    75 => x"00",
    76 => x"00",
    77 => x"00",
    78 => x"00",
    79 => x"00",
    80 => x"00",
    81 => x"00",
    82 => x"00",
    83 => x"00",
    84 => x"00",
    85 => x"00",
    86 => x"00",
    87 => x"00",
    88 => x"00",
    89 => x"00",
    90 => x"00",
    91 => x"00",
    92 => x"00",
    93 => x"00",
    94 => x"00",
    95 => x"00",
    96 => x"00",
    97 => x"00",
    98 => x"00",
    99 => x"00",
   100 => x"00",
   101 => x"00",
   102 => x"00",
   103 => x"00",
   104 => x"00",
   105 => x"00",
   106 => x"00",
   107 => x"00",
   108 => x"00",
   109 => x"00",
   110 => x"00",
   111 => x"00",
   112 => x"00",
   113 => x"00",
   114 => x"00",
   115 => x"00",
   116 => x"00",
   117 => x"00",
   118 => x"00",
   119 => x"00",
   120 => x"00",
   121 => x"00",
   122 => x"00",
   123 => x"00",
   124 => x"00",
   125 => x"00",
   126 => x"00",
   127 => x"00",
   128 => x"00",
   129 => x"00",
   130 => x"00",
   131 => x"00",
   132 => x"00",
   133 => x"00",
   134 => x"00",
   135 => x"00",
   136 => x"00",
   137 => x"00",
   138 => x"00",
   139 => x"00",
   140 => x"00",
   141 => x"00",
   142 => x"00",
   143 => x"00",
   144 => x"00",
   145 => x"00",
   146 => x"00",
   147 => x"00",
   148 => x"00",
   149 => x"00",
   150 => x"00",
   151 => x"00",
   152 => x"00",
   153 => x"00",
   154 => x"00",
   155 => x"00",
   156 => x"00",
   157 => x"00",
   158 => x"00",
   159 => x"00",
   160 => x"00",
   161 => x"00",
   162 => x"00",
   163 => x"00",
   164 => x"00",
   165 => x"00",
   166 => x"00",
   167 => x"00",
   168 => x"00",
   169 => x"00",
   170 => x"00",
   171 => x"00",
   172 => x"00",
   173 => x"00",
   174 => x"00",
   175 => x"00",
   176 => x"00",
   177 => x"00",
   178 => x"00",
   179 => x"00",
   180 => x"00",
   181 => x"00",
   182 => x"00",
   183 => x"00",
   184 => x"00",
   185 => x"00",
   186 => x"00",
   187 => x"00",
   188 => x"00",
   189 => x"00",
   190 => x"00",
   191 => x"00",
   192 => x"00",
   193 => x"00",
   194 => x"00",
   195 => x"00",
   196 => x"00",
   197 => x"00",
   198 => x"00",
   199 => x"00",
   200 => x"00",
   201 => x"00",
   202 => x"00",
   203 => x"00",
   204 => x"00",
   205 => x"00",
   206 => x"00",
   207 => x"00",
   208 => x"00",
   209 => x"00",
   210 => x"00",
   211 => x"00",
   212 => x"00",
   213 => x"00",
   214 => x"00",
   215 => x"00",
   216 => x"00",
   217 => x"00",
   218 => x"00",
   219 => x"00",
   220 => x"00",
   221 => x"00",
   222 => x"00",
   223 => x"00",
   224 => x"00",
   225 => x"00",
   226 => x"00",
   227 => x"00",
   228 => x"00",
   229 => x"00",
   230 => x"00",
   231 => x"00",
   232 => x"00",
   233 => x"00",
   234 => x"00",
   235 => x"00",
   236 => x"00",
   237 => x"00",
   238 => x"00",
   239 => x"00",
   240 => x"00",
   241 => x"00",
   242 => x"00",
   243 => x"00",
   244 => x"00",
   245 => x"00",
   246 => x"00",
   247 => x"00",
   248 => x"00",
   249 => x"00",
   250 => x"00",
   251 => x"00",
   252 => x"00",
   253 => x"00",
   254 => x"00",
   255 => x"00",
   256 => x"4f",
   257 => x"f9",
   258 => x"00",
   259 => x"00",
   260 => x"0f",
   261 => x"fe",
   262 => x"41",
   263 => x"f9",
   264 => x"00",
   265 => x"00",
   266 => x"02",
   267 => x"90",
   268 => x"20",
   269 => x"3c",
   270 => x"00",
   271 => x"00",
   272 => x"02",
   273 => x"90",
   274 => x"b1",
   275 => x"c0",
   276 => x"6c",
   277 => x"04",
   278 => x"42",
   279 => x"98",
   280 => x"60",
   281 => x"f8",
   282 => x"41",
   283 => x"fa",
   284 => x"00",
   285 => x"4e",
   286 => x"21",
   287 => x"c8",
   288 => x"00",
   289 => x"64",
   290 => x"41",
   291 => x"fa",
   292 => x"00",
   293 => x"54",
   294 => x"21",
   295 => x"c8",
   296 => x"00",
   297 => x"68",
   298 => x"41",
   299 => x"fa",
   300 => x"00",
   301 => x"5a",
   302 => x"21",
   303 => x"c8",
   304 => x"00",
   305 => x"6c",
   306 => x"41",
   307 => x"fa",
   308 => x"00",
   309 => x"60",
   310 => x"21",
   311 => x"c8",
   312 => x"00",
   313 => x"70",
   314 => x"41",
   315 => x"fa",
   316 => x"00",
   317 => x"66",
   318 => x"21",
   319 => x"c8",
   320 => x"00",
   321 => x"74",
   322 => x"41",
   323 => x"fa",
   324 => x"00",
   325 => x"6c",
   326 => x"21",
   327 => x"c8",
   328 => x"00",
   329 => x"78",
   330 => x"41",
   331 => x"fa",
   332 => x"00",
   333 => x"72",
   334 => x"21",
   335 => x"c8",
   336 => x"00",
   337 => x"7c",
   338 => x"48",
   339 => x"78",
   340 => x"00",
   341 => x"01",
   342 => x"48",
   343 => x"7a",
   344 => x"00",
   345 => x"0a",
   346 => x"4e",
   347 => x"b9",
   348 => x"00",
   349 => x"00",
   350 => x"02",
   351 => x"80",
   352 => x"60",
   353 => x"fe",
   354 => x"42",
   355 => x"6f",
   356 => x"6f",
   357 => x"74",
   358 => x"72",
   359 => x"6f",
   360 => x"6d",
   361 => x"00",
   362 => x"48",
   363 => x"e7",
   364 => x"ff",
   365 => x"fe",
   366 => x"48",
   367 => x"7a",
   368 => x"00",
   369 => x"5c",
   370 => x"2f",
   371 => x"3a",
   372 => x"00",
   373 => x"60",
   374 => x"4e",
   375 => x"75",
   376 => x"48",
   377 => x"e7",
   378 => x"ff",
   379 => x"fe",
   380 => x"48",
   381 => x"7a",
   382 => x"00",
   383 => x"4e",
   384 => x"2f",
   385 => x"3a",
   386 => x"00",
   387 => x"56",
   388 => x"4e",
   389 => x"75",
   390 => x"48",
   391 => x"e7",
   392 => x"ff",
   393 => x"fe",
   394 => x"48",
   395 => x"7a",
   396 => x"00",
   397 => x"40",
   398 => x"2f",
   399 => x"3a",
   400 => x"00",
   401 => x"4c",
   402 => x"4e",
   403 => x"75",
   404 => x"48",
   405 => x"e7",
   406 => x"ff",
   407 => x"fe",
   408 => x"48",
   409 => x"7a",
   410 => x"00",
   411 => x"32",
   412 => x"2f",
   413 => x"3a",
   414 => x"00",
   415 => x"42",
   416 => x"4e",
   417 => x"75",
   418 => x"48",
   419 => x"e7",
   420 => x"ff",
   421 => x"fe",
   422 => x"48",
   423 => x"7a",
   424 => x"00",
   425 => x"24",
   426 => x"2f",
   427 => x"3a",
   428 => x"00",
   429 => x"38",
   430 => x"4e",
   431 => x"75",
   432 => x"48",
   433 => x"e7",
   434 => x"ff",
   435 => x"fe",
   436 => x"48",
   437 => x"7a",
   438 => x"00",
   439 => x"16",
   440 => x"2f",
   441 => x"3a",
   442 => x"00",
   443 => x"2e",
   444 => x"4e",
   445 => x"75",
   446 => x"48",
   447 => x"e7",
   448 => x"ff",
   449 => x"fe",
   450 => x"48",
   451 => x"7a",
   452 => x"00",
   453 => x"08",
   454 => x"2f",
   455 => x"3a",
   456 => x"00",
   457 => x"24",
   458 => x"4e",
   459 => x"75",
   460 => x"4c",
   461 => x"df",
   462 => x"7f",
   463 => x"ff",
   464 => x"4e",
   465 => x"73",
   466 => x"4e",
   467 => x"75",
   468 => x"00",
   469 => x"00",
   470 => x"01",
   471 => x"d2",
   472 => x"00",
   473 => x"00",
   474 => x"01",
   475 => x"d2",
   476 => x"00",
   477 => x"00",
   478 => x"01",
   479 => x"d2",
   480 => x"00",
   481 => x"00",
   482 => x"01",
   483 => x"d2",
   484 => x"00",
   485 => x"00",
   486 => x"01",
   487 => x"d2",
   488 => x"00",
   489 => x"00",
   490 => x"01",
   491 => x"d2",
   492 => x"00",
   493 => x"00",
   494 => x"01",
   495 => x"d2",
   496 => x"46",
   497 => x"fc",
   498 => x"20",
   499 => x"00",
   500 => x"4e",
   501 => x"75",
   502 => x"46",
   503 => x"fc",
   504 => x"27",
   505 => x"00",
   506 => x"4e",
   507 => x"75",
   508 => x"00",
   509 => x"00",
   510 => x"00",
   511 => x"00",
   512 => x"cf",
   513 => x"00",
   514 => x"00",
   515 => x"00",
   516 => x"00",
   517 => x"00",
   518 => x"00",
   519 => x"00",
   520 => x"8c",
   521 => x"ff",
   522 => x"f0",
   523 => x"00",
   524 => x"00",
   525 => x"00",
   526 => x"00",
   527 => x"00",
   528 => x"08",
   529 => x"cc",
   530 => x"ff",
   531 => x"f0",
   532 => x"00",
   533 => x"00",
   534 => x"00",
   535 => x"00",
   536 => x"08",
   537 => x"cc",
   538 => x"cc",
   539 => x"ff",
   540 => x"ff",
   541 => x"00",
   542 => x"00",
   543 => x"00",
   544 => x"08",
   545 => x"8c",
   546 => x"cc",
   547 => x"cc",
   548 => x"cf",
   549 => x"ff",
   550 => x"00",
   551 => x"00",
   552 => x"00",
   553 => x"8c",
   554 => x"cc",
   555 => x"cc",
   556 => x"cc",
   557 => x"c8",
   558 => x"00",
   559 => x"00",
   560 => x"00",
   561 => x"88",
   562 => x"cc",
   563 => x"cc",
   564 => x"cc",
   565 => x"80",
   566 => x"00",
   567 => x"00",
   568 => x"00",
   569 => x"08",
   570 => x"cc",
   571 => x"cc",
   572 => x"cf",
   573 => x"00",
   574 => x"00",
   575 => x"00",
   576 => x"00",
   577 => x"08",
   578 => x"cc",
   579 => x"cc",
   580 => x"cc",
   581 => x"f0",
   582 => x"00",
   583 => x"00",
   584 => x"00",
   585 => x"08",
   586 => x"8c",
   587 => x"c8",
   588 => x"cc",
   589 => x"cf",
   590 => x"00",
   591 => x"00",
   592 => x"00",
   593 => x"00",
   594 => x"8c",
   595 => x"80",
   596 => x"8c",
   597 => x"cc",
   598 => x"f0",
   599 => x"00",
   600 => x"00",
   601 => x"00",
   602 => x"88",
   603 => x"00",
   604 => x"08",
   605 => x"cc",
   606 => x"cf",
   607 => x"00",
   608 => x"00",
   609 => x"00",
   610 => x"00",
   611 => x"00",
   612 => x"00",
   613 => x"8c",
   614 => x"cc",
   615 => x"f0",
   616 => x"00",
   617 => x"00",
   618 => x"00",
   619 => x"00",
   620 => x"00",
   621 => x"08",
   622 => x"cc",
   623 => x"c8",
   624 => x"00",
   625 => x"00",
   626 => x"00",
   627 => x"00",
   628 => x"00",
   629 => x"00",
   630 => x"8c",
   631 => x"80",
   632 => x"00",
   633 => x"00",
   634 => x"00",
   635 => x"00",
   636 => x"00",
   637 => x"00",
   638 => x"08",
   639 => x"00",
   640 => x"4e",
   641 => x"56",
   642 => x"00",
   643 => x"00",
   644 => x"42",
   645 => x"80",
   646 => x"33",
   647 => x"c0",
   648 => x"81",
   649 => x"00",
   650 => x"00",
   651 => x"06",
   652 => x"52",
   653 => x"80",
   654 => x"60",
   655 => x"f6",
	others => x"00"
);

begin

-- We use a dual-port RAM here - one port for the lower byte, one for the upper byte.  This allows us to
-- present a 16-bit interface while allowing byte writes.

process (clk)
begin
	if (clk'event and clk = '1') then
		if we_n = '0' and lds_n='0' then
			ram(to_integer(unsigned(addr(maxAddrBitBRAM downto 1)&'1'))) := d(7 downto 0);
			q(7 downto 0) <= d(7 downto 0);
		else
			q(7 downto 0) <= ram(to_integer(unsigned(addr(maxAddrBitBRAM downto 1)&'1')));
		end if;
	end if;
end process;

process (clk)
begin
	if (clk'event and clk = '1') then
		if we_n = '0' and uds_n='0' then
			ram(to_integer(unsigned(addr(maxAddrBitBRAM downto 1)&'0'))) := d(15 downto 8);
			q(15 downto 8) <= d(15 downto 8);
		else
			q(15 downto 8) <= ram(to_integer(unsigned(addr(maxAddrBitBRAM downto 1)&'0')));
		end if;
	end if;
end process;

end arch;
