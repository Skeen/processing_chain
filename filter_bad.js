#!/usr/bin/env node
'use strict';

var readline = require('readline');

var read_json = function(callback)
{
    var rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: false
    });

    var input = "";
    rl.on('line', function(line)
    {
        input += line;
    });

    rl.on('close', function()
    {
        var json;
        try
        {
            json = JSON.parse(input);
        }
        catch(err)
        {
            console.error();
            console.error("Fatal error: Piped input is not valid JSON!");
            console.error();
            console.error(err);
            process.exit(1);
        }

        callback(json);
    });
};

var reject_percentage = parseFloat(process.argv[2]);
console.log(reject_percentage);

read_json(function(json)
{
    Object.keys(json).filter(function(ground_truth)
    {
        var accurate = (json[ground_truth][ground_truth] || 0);
        console.log(ground_truth, accurate);
    });
});
