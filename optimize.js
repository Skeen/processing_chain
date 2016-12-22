#!/usr/bin/env node

var fs = require('fs');
var exec = require('child_process').exec;
var make = function(callback)
{
    var command = 'KNN_CONFUSION_ARGS="-M --knn=' + knn + ' -n ' + std_dev + ' -q ' + cutoff + '" make ; state=' + state;
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

var visited = {};

var max_accuracy = 0;
var old_accuracy = 0;
function improve(accuracy)
{
    // Detect if we're in a position we've previously been in
    if(visited[knn] && visited[knn][std_dev] && visited[knn][std_dev][cutoff] && visited[knn][std_dev][cutoff][state])
    {
        console.log("cycle detected!");
        return;
    }
    visited[knn] = (visited[knn] || {});
    visited[knn][std_dev] = (visited[knn][std_dev] || {});
    visited[knn][std_dev][cutoff] = (visited[knn][std_dev][cutoff] || {});
    visited[knn][std_dev][cutoff][state] = (visited[knn][std_dev][cutoff][state] || {});
    
    // Keep track of our best so far
    max_accuracy = Math.max(max_accuracy, accuracy);
    console.log("acc:", Math.round(accuracy * 100)/100, "max", Math.round(max_accuracy * 100) / 100);

    apply();
    if(accuracy < old_accuracy) // If we did worse, revert and switch approach
    {
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

            improve(accuracy);
        });
    });
}

take_reading();
