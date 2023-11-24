/* Q1: Who is the senior most employee based on job title? */

SELECT * FROM employee
order by levels desc
limit 1

/* Q2: Which countries have the most Invoices? */

SELECT count(billing_country),billing_country FROM invoice
GROUP BY billing_country
ORDER BY billing_country DESC

/* Q3: What are top 3 values of total invoice? */

SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city
we made the most money. Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

SELECT billing_city, SUM(total) AS invoice_total FROM invoice
GROUP BY billing_city 
ORDER BY invoice_total DESC
limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select * from customer

SELECT customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) AS spent
FROM customer 
join invoice ON
customer.customer_id=invoice.customer_id
GROUP BY customer.customer_id
ORDER BY spent DESC
limit 1

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT customer.email,customer.first_name, customer.last_name, genre.name
from customer 
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
ORDER BY email

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
 
 SELECT count(artist.artist_id) as  totalcount, artist.name FROM artist
 join album on album.artist_id=artist.artist_id
 join track on track.album_id=album.album_id
 join genre on genre.genre_id=track.genre_id
 WHERE genre.name LIKE 'Rock'
 GROUP BY artist.artist_id
 order by totalcount DESC
 LIMIT 10
 
 /* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name, milliseconds FROM track
where milliseconds > (
	select avg(milliseconds) from track 
)
ORDER BY milliseconds DESC

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

WITH best_selling_artist AS(
	SELECT artist.name, artist.artist_id, sum(invoice_line.unit_price * invoice_line.quantity) AS totalsales
	FROM artist 
	JOIN album on artist.artist_id=album.artist_id
	JOIN track on album.album_id=track.album_id
	JOIN invoice_line on track.track_id=invoice_line.track_id
	GROUP BY artist.artist_id	
	ORDER BY totalsales DESC
	limit 1
)

SELECT customer.customer_id, customer.first_name, customer.last_name, best_selling_artist.name, SUM(invoice_line.unit_price * invoice_line.quantity) as totalspent
from customer
join invoice on invoice.customer_id=customer.customer_id
join invoice_line on invoice.invoice_id= invoice_line.invoice_id
join track on track.track_id=invoice_line.track_id
join album on album.album_id=track.album_id
join artist on artist.artist_id=album.artist_id
join best_selling_artist on artist.artist_id=best_selling_artist.artist_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name, best_selling_artist.name
order by totalspent

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */ 

with new_table as(
	select count(invoice_line.quantity) as purchase, genre.genre_id,genre.name, customer.country,
	ROW_NUMBER() over(partition by customer.country order by count(invoice_line.quantity) DESC) AS rowno
	from genre
	join track on track.genre_id=genre.genre_id
	join invoice_line on invoice_line.track_id=track.track_id
	join invoice on invoice.invoice_id=invoice_line.invoice_id
	join customer on customer.customer_id=invoice.customer_id
	group by genre.genre_id,genre.name,customer.country
	order by purchase DESC
)

SELECT * FROM new_table where rowno<=1

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

with most_spent_customer AS(
	SELECT customer.customer_id, customer.first_name,customer.last_name, customer.country, sum(total),
	row_number( ) over(partition by customer.country order by sum(total) DESC) as rowno
	from customer
	join invoice on invoice.customer_id=customer.customer_id
	join invoice_line on invoice_line.invoice_id=invoice.invoice_id
	GROUP BY customer.customer_id, customer.first_name,customer.last_name,customer.country
	ORDER BY customer.country ASC, sum(total) DESC
)
select * from most_spent_customer where rowno <= 1
