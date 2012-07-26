PrimaveraConnector
==================

Proof of concept code for a Rally &lt;-&gt; Primavera integration

This Ruby implementation aggregates Rally TimeEntryItem/TimeEntryValue information
and updates Primavera with those aggregated values

It depends on having the following gems installed:

    savon 
    rally_rest_api


This implementation was tested with Ruby 1.9.2-p290.  While it is likely that
the code will work with later versions of Ruby, that has not been tested.
There is less likelihood that this code will work with older versions of Ruby.
