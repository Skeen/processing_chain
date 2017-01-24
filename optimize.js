#!/usr/bin/env node

var fs = require('fs');
var exec = require('child_process').exec;
var make = function(callback)
{
    var command = 'KNN_CONFUSION_ARGS="-w d --knn=' + knn + ' -n ' + std_dev + ' -q ' + cutoff + '" make ;state=' + JSON.stringify(state);
    console.log(command);
    exec(command, {maxBuffer: Number.POSITIVE_INFINITY},
            callback);    
}

var knn = 3;
var std_dev = 1.5;
var cutoff = 10;

var std_dev_change = 0.05;

var state = {};
reset_state();
function reset_state()
{
    state["K"] = 1;
    state["S"] = 1;
    state["C"] = 1;
}

var last_state = {};

function apply()
{
    switch(state["K"])
    {
        case 1:
            break;
        case 2:
            knn++;
            break;
        case 3:
            knn = Math.max(knn - 1, 1);
            break;
    }

    switch(state["S"])
    {
        case 1:
            break;
        case 2:
            cutoff += 1;
            break;
        case 3:
            cutoff = Math.max(cutoff - 1, 0);
            break;
    }

    switch(state["C"])
    {
        case 1:
            break;
        case 2:
            std_dev += std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
        case 3:
            std_dev -= std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
    }

    last_state = state;
}

function state_increment()
{
    state["K"]++;

    if (state["K"] > 3)
    {
        state["K"] = 1;
        state["S"]++;
    }
    if (state["S"] > 3)
    {
        state["S"] = 1;
        state["C"]++;
    }
    if (state["C"] > 3)
    {
        state["C"] = 1;
    }
}

function undo()
{
    switch(last_state["K"])
    {
        case 1:
            break;
        case 2:
            knn = Math.max(knn - 1, 1);
            break;
        case 3:
            knn++;
            break;
    }

    switch(last_state["S"])
    {
        case 1:
            break;
        case 2:
            cutoff = Math.max(cutoff - 1, 0);
            break;
        case 3:
            cutoff += 1;
            break;
    }

    switch(last_state["C"])
    {
        case 1:
            break;
        case 2:
            std_dev -= std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
        case 3:
            std_dev += std_dev_change;
            std_dev = Math.round(std_dev * 100) / 100;
            break;
    }
}

var visited = {};

var max_accuracy = 0;
var old_accuracy = 0;
function improve(accuracy)
{
    var key = state['K'] + state['S'] * 10 + state['C'] * 100;
    // If we're in 111 (do nothing, change to 112)
    if(key == 111)
    {
        state_increment();
        take_reading();
        return;
    }

    // Detect if we're in a position we've previously been in
    if(visited[knn] && 
        visited[knn][std_dev] && 
        visited[knn][std_dev][cutoff] && 
        visited[knn][std_dev][cutoff][key]
        )
    {
        state_increment();
        take_reading();
        return;
    }
    // Detect if we're in a position we've previously been in
    if(visited[knn] && 
        visited[knn][std_dev] && 
        visited[knn][std_dev][cutoff] && 
        Object.keys(visited[knn][std_dev][cutoff]).length == 9
        )
    {
        console.error("Search exhausted!");
        console.log(max_config);
        return;
    }
    visited[knn] = (visited[knn] || {});
    visited[knn][std_dev] = (visited[knn][std_dev] || {});
    visited[knn][std_dev][cutoff] = (visited[knn][std_dev][cutoff] || {});
    visited[knn][std_dev][cutoff][key] = (visited[knn][std_dev][cutoff][key] || key);
    // Keep track of our best so far
    if(accuracy >= max_accuracy)
    {
        max_accuracy = accuracy;
        max_config = 'KNN_CONFUSION_ARGS="-w d --knn=' + knn + ' -n ' + std_dev + ' -q ' + cutoff;
    }
    console.log();
    console.log("acc:", Math.round(accuracy * 100)/100, "max", Math.round(max_accuracy * 100) / 100);
    console.log("key:", key, "tried:", Object.keys(visited[knn][std_dev][cutoff]).length);

    // If we did worse, undo and try another approach
    if(accuracy <= old_accuracy)
    {
        undo();
        state_increment();
    }
    old_accuracy = accuracy;

    apply();
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
