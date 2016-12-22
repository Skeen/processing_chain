#!/usr/bin/env node

var fs = require('fs');
var exec = require('child_process').exec;
var make = function(callback)
{
    var command = 'KNN_CONFUSION_ARGS="-M --knn=' + knn + ' -n ' + std_dev + ' -q ' + cutoff + '" make';
    console.log(command);
    exec(command, callback); 
}

var knn = 0;
var std_dev = 1;
var cutoff = 0;

var std_dev_change = 0.05;

var state = 1;

function apply()
{
    switch(state)
    {
        case 1:
            knn++;
            break;
        case 3:
            std_dev += std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
        case 2:
            cutoff += 1;
            break;
        case 4:
            knn = Math.max(knn - 1, 0);
            break;
        case 6:
            std_dev -= std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
        case 5:
            cutoff = Math.max(cutoff - 1, 0);
            break;
    }
}

function undo()
{
    switch(state)
    {
        case 1:
            knn = Math.max(knn - 1, 0);
            break;
        case 3:
            std_dev -= std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
        case 2:
            cutoff = Math.max(cutoff - 1, 0);
            break;
        case 4:
            knn++;
            break;
        case 6:
            std_dev += std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
        case 5:
            cutoff += 1;
            break;
    }
}

var old_accuracy = 0;
function improve(accuracy)
{
    apply();
    if(accuracy > old_accuracy)
    {
        //console.log("accuracy improved!");
    }
    else
    {
        console.log("accuracy falled!");
        undo();

        state++;
        if(state == 7)
            state = 1;

        apply();
    }
    old_accuracy = accuracy;
    take_reading();
}

function take_reading()
{
    make(function(error, stdout, stderr)
    {
        if (error) {
            console.error("Exec error:", error);
            return;
        }
        //console.log("stdout:", stdout);
        if(stderr.length > 0)
            console.log("stderr:", stderr);

        fs.readFile('output/render/resume.json', 'utf8', function(err, data)
        {
            if(err)
            {
                console.error(err);
                return;
            }
            var json = JSON.parse(data);
            var accuracy = json.accuracy;

            console.log(accuracy);

            improve(accuracy);
        });
    });
}

take_reading();
