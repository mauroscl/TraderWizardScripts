select s1.Codigo, (s2.ValorMaximo / s1.ValorFechamento -1) * 100 as percentual
from 
(SELECT Codigo, ValorFechamento
FROM Cotacao_Semanal c
WHERE c.DATA = '2021-2-17'
AND C.Negocios_Total >= 500
AND C.Titulos_Total >=500000
AND C.Valor_Total >= 5000000

)  as s1
inner join
(SELECT Codigo, ValorMaximo
FROM Cotacao_Semanal
WHERE DATA = '2021-2-22') as  s2
on s1.Codigo = s2.Codigo
order by 2 desc