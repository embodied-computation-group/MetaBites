function [results]=foodRatings(p, results, likert)

if likert==1
       [results] = foodRatingsLikert(p, results);
elseif likert==0
        [results] = foodYesNo(p, results);
     foodYesNo(p, results);
end
        
end




