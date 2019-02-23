-- The MIT License (MIT)
--
-- Copyright (c) 2019 Jens Brauer
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

Exporter{version          = 1.00,
         format           = "Bar Charts (In/Out/Diff per Month)",
         fileExtension    = "html",
         reverseOrder     = true,
         description      = "Export Bar Charts to HTML"}

local function writeDataSet (data, dataType)
  -- Helper function for writing dataset of yearly in/out/diff dataset to file
  -- inputs: data - the dataset
  --         dataType - 0 income, 1: outgoing, 2: difference
  for m,d in ipairs(data) do
    if m == 1 then
      assert(io.write("["))
    end
    if dataType == 0 then
      amountInOutDiff = string.format("%.2f", d[0])
    elseif dataType == 1 then
      amountInOutDiff = string.format("%.2f", -d[1])
    elseif dataType == 2 then
      amountInOutDiff = string.format("%.2f", d[0] + d[1])
    end
    assert(io.write(amountInOutDiff))
    if m<12 then
      assert(io.write(","))
    end
    if m==12 then
      assert(io.write("]"))
    end
  end
end

function WriteHeader (account, startDate, endDate, transactionCount)
  assert(io.write([[
    <!doctype html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>]] .. account.name .. [[, ]] .. os.date("%d.%m.%Y", startDate) .. [[ - ]] .. os.date("%d.%m.%Y", endDate) .. [[</title>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.3/Chart.min.js"></script> 
    </head>
    <body>
  ]]))

  currMonth = -1
  currYear = -1
  currAmountIn = 0
  currAmountOut = 0
  newMonth = false
  newYear = false
  data = {}
  yearCount = 0
  excludeCategory = false
  excludeCategoryName = "Umbuchung"
end

-- called for every booking day
function WriteTransactions (account, transactions)

    -- Write transactions.
    for _,transaction in ipairs(transactions) do

      year = tonumber(os.date("%Y", transaction.bookingDate))
      month = tonumber(os.date("%m",  transaction.bookingDate))

      -- check for new month
      if not(month == currMonth) then
        newMonth = true
      end

      -- check for new year
      if not(year == currYear) then
        newYear = true;
        currYear = year;
        data[year] = {}
        for m=1,12 do
          data[year][m] = {}
          data[year][m][0] = 0
          data[year][m][1] = 0
        end
        yearCount = yearCount + 1
      end
      
      --Dump
      --dump = string.format("Dump %d %d %d %f %s\n", currMonth, month, year, currAmountIn, transaction.category)
      --assert(io.write(dump))

      if newMonth == true then
        newMonth = false
        currAmountIn = 0
        currAmountOut = 0
        currMonth = month
      end

      -- Exclude category (e.g. "Umbuchung")
      if excludeCategory and string.find(transaction.category, excludeCategoryName) then goto continue end

      -- Check if incoming or outgoing
      amount = transaction.amount
      if amount >0 then
          data[year][month][0] = data[year][month][0] + amount
      end

      if amount <0 then
          data[year][month][1] = data[year][month][1] + amount
      end

      ::continue::

    end
end

-- Write the end
function WriteTail (account)

  -- Heading and Canvas Container
  for y = currYear-yearCount+1,currYear do
    assert(io.write(
    [[
    <h1 align="center">]] .. y .. [[</h1>
    <canvas id="myChart]] .. y .. [[" width="500" height="100"></canvas>
    ]]))
  end

  

  for y = currYear-yearCount+1,currYear do
    assert(io.write(
    [[
      <script>
      var data = {
        labels: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "Oktober", "November", "Dezember"],
        datasets: [
    ]]))

    -- Write income
    assert(io.write("\t{"))
    assert(io.write([[
                    label:"In",
                    backgroundColor: "rgba(139, 195, 74,1.0)",
                    strokeColor: "rgba(220,220,220,0.8)",
                    highlightFill: "rgba(220,220,220,0.75)",
                    highlightStroke: "rgba(220,220,220,1)",
    ]]))
    assert(io.write("data:"))
    writeDataSet(data[y], 0)
    assert(io.write("\t}\n,"))

    -- Write outgoing
    assert(io.write("{\n"))
    assert(io.write([[
                    label:"Out",
                    backgroundColor: "rgba(244, 67, 54,1.0)",
                    strokeColor: "rgba(151,187,205,0.8)",
                    highlightFill: "rgba(151,187,205,0.75)",
                    highlightStroke: "rgba(151,187,205,1)",
    ]]))
    assert(io.write("data:"))
    writeDataSet(data[y], 1)
    assert(io.write("\n},"))

    -- Write difference
    assert(io.write("{\n"))
    assert(io.write([[
                  label:"Diff",
                  backgroundColor: "rgba(3, 169, 244,1.0)",
                  strokeColor: "rgba(151,187,205,0.8)",
                  highlightFill: "rgba(151,187,205,0.75)",
                  highlightStroke: "rgba(151,187,205,1)",
    ]]))
    assert(io.write("data:"))
    writeDataSet(data[y], 2)
    assert(io.write("}]};\n\n"))

    -- Write options and script to create the bar chart
    assert(io.write([[
      var options = {
        scaleBeginAtZero: false,
        responsive: true,
        scaleStartValue : -50 
      };

      var ctx = document.getElementById("myChart]] .. y .. [[").getContext("2d");

      var myBarChart = new Chart(ctx, {type: 'bar', data: data});
    </script>
    ]]))

  end

  assert(io.write([[
    </body>
    </html>
  ]]))
end