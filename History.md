0.0.8: jun 13 2016

- keep memory consumption low after running for a while
- synchronize write on string buffer

0.0.7: dec 20 2013

- made the event source and server sent events conform to nscopying, nscoding
- able to remove event handlers from the event source

0.0.6: dec 14 2013

- set internal state and make delegate calls in reponse to url session

0.0.5: dec 6 2013

- notify delegates after internal state is changed

0.0.4: dec 5 2013

- improve resource cleanup when close: is called

0.0.3: dec 5 2013

- move open call out of init so the delegate can be set

0.0.2: dec 4 2013

- ensure eventsourcedidopen: is called

0.0.1: oct 8 2013

- initial version
