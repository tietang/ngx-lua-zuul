--
-- User: Tietang Wang 铁汤 
-- Date: 16/8/25 09:58
-- Blog: http://tietang.wang
--

accept = "text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5;application/json"

print(string.match(accept, "application/json"))
print(string.match(accept, "text/html"))