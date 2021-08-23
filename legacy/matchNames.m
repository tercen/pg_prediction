function idx = matchNames(name, list)
idx = find(strcmp(name, list));
idx = idx(1);