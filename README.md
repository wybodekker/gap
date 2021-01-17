# gap
|     key | description
|     ---:|:---
|  script | gap - report gaps, inversions, and repeats in numerical columns
|    type | bash
|  author | Wybo Dekker
|   email | wybo@dekkerdocumenten.nl
| version | 3.00
| license | GNU General Public License

gap inspects (supposedly sorted, decimal) numerical columns in tab-separated databases
and reports missing numbers, duplications and inversions. Columns are counted starting at 1.
gap can also read from standard input. Leading zeros are stripped from numbers before use.
