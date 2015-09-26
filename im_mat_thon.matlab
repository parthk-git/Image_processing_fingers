finger=uint8(1); %denotes number of fingers detected at start
cam=webcam; %initiating webcam
preview(cam);

disp('ready to take snap');
I=snapshot(cam);

%this while loop adjusts so that 5 fingers are detected properly
while finger~=5 
	final_image = zeros(size(I,1), size(I,2));
	    for i = 1:size(I,1)
	        for j = 1:size(I,2)
	            R = I(i,j,1);
	            G = I(i,j,2);
	            B = I(i,j,3);

	            if(R > 95 && G > 40 && B > 20)
	                v = [R,G,B];
	                if((max(v) - min(v)) > 15)
	                    if(abs(R-G) > 15 && R > G && R > B)

	                        %it is a skin color
	                        final_image(i,j) = 1;
	                    end
	                end
	            end
	        end
	    end

	blobs_removed = bwareaopen(final_image, 50);

	se = strel('line',11,90);
	dilated=imdilate(blobs_removed,se);

	dilated = bwareaopen(dilated,100);

	[L,num]=bwlabel(dilated);

	max_area=0;
	label=0;
	for k = 1:num
	    area=0;
	    for i = 1:size(L,1)
	        for j = 1:size(L,2)
	            if(L(i,j)==k)
	                area=area+1;
	            end
	        end
	    end
	    if(area>max_area)
	        max_area=area;
	        label=k;
	    end
	end

	final_palm = zeros(size(L,1), size(L,2));
	for i = 1:size(L,1)
	    for j = 1:size(L,2)
	        if(L(i,j)==label)
	            final_palm(i,j)=1;
	        end
	    end
	end

	x_centroid=0;
	y_centroid=0;
	count=1;
	for i = 1:size(final_palm,1)
	        for j = 1:size(final_palm,2)
	          if(final_palm(i,j)==1)
	            count=count+1;
	            y_centroid= ((y_centroid * (count-1)) + i)/count;
	            x_centroid= ((x_centroid * (count-1)) + j)/count;
	          end
	        end
	end

	%centroid of the palm 
	x_centroid=floor(x_centroid);
	y_centroid=floor(y_centroid)+40;

	count=0;
	for i = x_centroid:size(final_palm,2)
	    if(final_palm(y_centroid,i)==0)
	        count=count+1;
	        if(count==30)
	            break;
	        end
	    end
	end

	count=0;
	for j = y_centroid:size(final_palm,1)
	    if(final_palm(j,x_centroid)==0)
	        count=count+1;
	        if(count==30)
	            break;
	        end
	    end
	end

	palm_width = (i- x_centroid);
	palm_height = (j - y_centroid);


	final_palm1=final_palm;

	img_width =  size(final_palm1,2);
	%height of image in pixels
	img_height = size(final_palm1,1);

	img_first=final_palm1;

	%the number of black dots which we get in between due to overlap of two fingers
	%if less than neglect value that means finger not changed just some small disturbance
	%play with this value
	neglect=100;

	% determine jumps in which we will look for first white pixel of start image...see for loop of start will understand better 
	parts = uint8(10);

	%signifies the change in number of fingers due to overlap... if 2 fingers overlap change is  1... if 3 overlap then 2
	changed = uint16(0);

	%indicates whether any white pixel present in a column or not
	present = false;

	%keeps a count of number of consecutive black columns 
	present_false_counter = 0;

	%stores the y coordinate of the previous column where the white pixel first appeared... useful to know if overlap over or if left overlap started.....
	first_seen = int32(-1);

	% play with this.... threshold for difference between first_seens of 2 consecutive columns .... if large that means new finger has started 
	new_finger_distance= 100;

	finger = uint8(1) 

	% left overlap happening or not
	left_overlap = false;
	right_start_j=uint16(0);
	right_start_i=uint16(0);
	left_start_j=uint16(0);
	left_start_i=uint16(0);
	%white pixels appear together or none at all
	only_continuous_white = true;


	    
	    for i = img_width : -8 : 1
	        for j = 1 : 1 : img_height
	            if(img_first(j,i) == 1)
	                right_start_j = j;
	                right_start_i = i;
	                break; % just check if IF statement returns this and not for loop!
	            end
	        end
	        if (right_start_j ~= 0)
	            break;
	        end
	    end



	    for i = 1 : 8 : img_width
	        for j = 1 : 1 : img_height
	            if img_first(j,i) == 1
	                left_start_i = i;
	                left_start_j = j;
	                break;
	            end
	        end
	        if (left_start_j ~= 0)              
	        	break;
	        end
	    end

	%right_left = 0 for right and 1 for left
	if(right_start_j > left_start_j)
	    right_left = 0;
	else
	    right_left = 1; 
	end

	%remove corresponding rectangle so only fingers are seen unattached
	if(right_left==0)
	 for p = 1:floor(x_centroid + (palm_width/2))
	        for q = floor(y_centroid - (palm_height * 0.6)):size(final_palm,1)
	            final_palm1(q,p)=0;
	        end
	 end
	end

	if(right_left==1)
	 for p = floor(x_centroid - (palm_width/2)):size(final_palm,2)
	        for q = floor(y_centroid - (palm_height * 0.6)):size(final_palm,1)
	            final_palm1(q,p)=0;
	        end
	 end
	end

	img_first=final_palm1;

	finger_no = uint16(1); %finger indexing from the left
	last_seen = uint16(0); %last white seen for so that we can identify change in finger....discussed on phone... see function mein use for clarity

	little_finger=zeros(1,2);
	ring_finger=zeros(1,2);
	middle_finger=zeros(1,2);
	index_finger=zeros(1,2);
	thumb_finger=zeros(1,2);

	for i = left_start_i : 1 : right_start_i  
	            for j = 1 : 1 : img_height
	                if (img_first(j,i) == 1)
	                    present = true;
	                    present_false_counter = 0;
	                    
	                    %by this i mean that new finger has started after finish in overlap.... like thumb after finish in overlap
	                    if (last_seen == 0)
	                        if (abs(j - first_seen) > new_finger_distance &&  first_seen ~= -1) 
	                        	finger = finger + 1; 
	                            finger_no=finger_no+1; %new finger started

	                            %new finger due to left overlap
	                            if (j - first_seen < 0)
	                            	left_overlap = true;
	                            end
	                        end

	                        first_seen = j ; %updates first seen for future reference
	                    end

	                    %still adding coordinates of same finger
	                    if (last_seen == 0 || (j - last_seen < neglect))                        
	                        newrow=[j i];
	                        if(right_left==0) 
	                            if(finger_no==1)
	                                little_finger=[little_finger;newrow];
	                
	                            elseif(finger_no==2)
	                                ring_finger=[ring_finger;newrow];
	                             
	                            elseif(finger_no==3)
	                                middle_finger=[middle_finger;newrow];
	                            
	                            elseif(finger_no==4)
	                                index_finger=[index_finger;newrow];
	                            
	                            elseif(finger_no==5)
	                                thumb_finger=[thumb_finger;newrow];
	                            end
	                        
	                        else 
	                            if(finger_no==1)
	                                thumb_finger=[thumb_finger;newrow];
	                            
	                            elseif(finger_no==2)
	                                index_finger=[index_finger;newrow];
	                            
	                            elseif(finger_no==3)
	                                middle_finger=[middle_finger;newrow];
	                             
	                            elseif(finger_no==4)
	                                ring_finger=[ring_finger;newrow];
	                            
	                            elseif(finger_no==5)
	                                little_finger=[little_finger;newrow];
	                            end
	                        end
	                        last_seen = j;
	                    

	                    %white pixels reappear after a definite gap
	                    else
	                        %white pixels of next finger
	                        last_seen = j;
	                        if (left_overlap == false)
	                            finger_no=finger_no+1;
	                            changed=changed+1;
	                            only_continuous_white = false;
	                            newrow=[j i];
	                            if(right_left==0) 
	                                if(finger_no==1)
	                                    little_finger=[little_finger;newrow];
	                                
	                                elseif(finger_no==2)
	                                    ring_finger=[ring_finger;newrow];
	                                
	                                elseif(finger_no==3)
	                                    middle_finger=[middle_finger;newrow];
	                                
	                                elseif(finger_no==4)
	                                    index_finger=[index_finger;newrow];
	                                
	                                elseif(finger_no==5)
	                                    thumb_finger=[thumb_finger;newrow];
	                                end
	                            
	                            else 
	                                if(finger_no==1)
	                                    thumb_finger=[thumb_finger;newrow];
	                                
	                                elseif(finger_no==2)
	                                    index_finger=[index_finger;newrow];
	                                
	                                elseif(finger_no==3)
	                                    middle_finger=[middle_finger;newrow];
	                                
	                                elseif(finger_no==4)
	                                    ring_finger=[ring_finger;newrow];
	                                
	                                elseif(finger_no==5)
	                                    little_finger=[little_finger;newrow];
	                                end
	                            end
	                        
	                        %white pixels due to previous finger....that is left overlap
	                        else
	                            finger_no=finger_no-1;
	                            changed=changed-1;
	                            only_continuous_white = false;
	                            newrow=[j i];
	                            if(right_left==0) 
	                                if(finger_no==1)
	                                    little_finger=[little_finger;newrow];
	                                
	                                elseif(finger_no==2)
	                                    ring_finger=[ring_finger;newrow];
	                                 
	                                elseif(finger_no==3)
	                                    middle_finger=[middle_finger;newrow];
	                                
	                                elseif(finger_no==4)
	                                    index_finger=[index_finger;newrow];
	                                
	                                elseif(finger_no==5)
	                                    thumb_finger=[thumb_finger;newrow];
	                                end
	                            
	                            else 
	                                if(finger_no==1)
	                                    thumb_finger=[thumb_finger;newrow];
	                                
	                                elseif(finger_no==2)
	                                    index_finger=[index_finger;newrow];
	                                
	                                elseif(finger_no==3)
	                                    middle_finger=[middle_finger;newrow];
	                                
	                                elseif(finger_no==4)
	                                    ring_finger=[ring_finger;newrow];
	                                
	                                elseif(finger_no==5)
	                                    little_finger=[little_finger;newrow];
	                                end
	                            end
	                        end                 
	                    end
	                end
	            end
	            if (present == false) % that is we get a black column
	                first_seen = -1;
	                if(present_false_counter == 0) %ensures finger addition takes place only once due to black columns  
	                    finger = finger + 1; 
	                    finger_no=finger_no+1;
	                    present_false_counter=present_false_counter+1;
	                end
	            end
	            
	            % left_overlap has ended
	            if(only_continuous_white == true)
	                left_overlap = false;
	            end

	            %resetting conditions for new columns
	            only_continuous_white = true;
	            present = false;
	            finger_no = finger_no - changed;
	            changed = 0;
	            last_seen = 0;
	end

	disp(finger);

	min_0_y = uint16(img_height);
	    min_1_y = uint16(img_height);
	    min_2_y = uint16(img_height);
	    min_3_y = uint16(img_height);
	    min_4_y = uint16(img_height);

	if(right_left==0)
	    %first finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=little_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_0_y)
	            min_0_y = finger_in_use(i,1);
	            min_0_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);
	    
	    x_0_ref = x_sum;
	    y_0_ref = y_sum;
	    
	   %second finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=ring_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_1_y)
	            min_1_y = finger_in_use(i,1);
	            min_1_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);
	    
	    x_1_ref = x_sum;
	    y_1_ref = y_sum;

	    %third finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=middle_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_2_y)
	            min_2_y = finger_in_use(i,1);
	            min_2_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_2_ref = x_sum;
	    y_2_ref = y_sum;

	    %fourth finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=index_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_3_y)
	            min_3_y = finger_in_use(i,1);
	            min_3_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_3_ref = x_sum;
	    y_3_ref = y_sum;

	    %fifth finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=thumb_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_4_y)
	            min_4_y = finger_in_use(i,1);
	            min_4_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_4_ref = x_sum;
	    y_4_ref = y_sum;
	end

	if(right_left==1)
	    %first finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=thumb_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_0_y)
	            min_0_y = finger_in_use(i,1);
	            min_0_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_0_ref = x_sum;
	    y_0_ref = y_sum;
	    
	   %second finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=index_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_1_y)
	            min_1_y = finger_in_use(i,1);
	            min_1_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_1_ref = x_sum;
	    y_1_ref = y_sum;

	    %third finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=middle_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_2_y)
	            min_2_y = finger_in_use(i,1);
	            min_2_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_2_ref = x_sum;
	    y_2_ref = y_sum;

	    %fourth finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=ring_finger;
	    for i = 2 : 1 : size(finger_in_use,1)      
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_3_y)
	            min_3_y = finger_in_use(i,1);
	            min_3_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_3_ref = x_sum;
	    y_3_ref = y_sum;

	    %fifth finger
	    x_sum=0;
	    y_sum=0;
	    finger_in_use=little_finger;
	    for i = 2 : 1 : size(finger_in_use,1)     
	        x_sum = x_sum + finger_in_use(i,2);
	        y_sum = y_sum + finger_in_use(i,1);
	        if (finger_in_use(i,1) < min_4_y)
	            min_4_y = finger_in_use(i,1);
	            min_4_x = finger_in_use(i,2);
	        end
	    end

	    x_sum = x_sum / size(finger_in_use,1);
	    y_sum = y_sum / size(finger_in_use,1);

	    x_4_ref = x_sum;
	    y_4_ref = y_sum;
	end

	if(finger>5)
	  neglect=neglect+10;
	  new_finger_distance=new_finger_distance+10;
	end

	if(finger<5)
	  neglect=neglect-10;
	  new_finger_distance=new_finger_distance-10;
	end
    
    I=snapshot(cam);

end

disp('ready');

while 1
		%taking new image with bent fingers 
	  I1=snapshot(cam);
	     final_image = zeros(size(I1,1), size(I1,2));

	    for i = 1:size(I1,1)
	        for j = 1:size(I,2)
	            R = I1(i,j,1);
	            G = I1(i,j,2);
	            B = I1(i,j,3);

	            if(R > 95 && G > 40 && B > 20)
	                v = [R,G,B];
	                if((max(v) - min(v)) > 15)
	                    if(abs(R-G) > 15 && R > G && R > B)

	                        %it is a skin color
	                        final_image(i,j) = 1;
	                    end
	                end
	            end
	        end
	    end

	blobs_removed = bwareaopen(final_image, 50);

	se = strel('line',11,90);
	dilated=imdilate(blobs_removed,se);

	dilated = bwareaopen(dilated,100);

	[L,num]=bwlabel(dilated);

	max_area=0;
	label=0;
	for k = 1:num
	    area=0;
	    for i = 1:size(L,1)
	        for j = 1:size(L,2)
	            if(L(i,j)==k)
	                area=area+1;
	            end
	        end
	    end
	    if(area>max_area)
	        max_area=area;
	        label=k;
	    end
	end

	final_palm = zeros(size(L,1), size(L,2));
	for i = 1:size(L,1)
	    for j = 1:size(L,2)
	        if(L(i,j)==label)
	            final_palm(i,j)=1;
	        end
	    end
	end

	x_0_ref=floor(x_0_ref);
	y_0_ref=floor(y_0_ref);
	x_1_ref=floor(x_1_ref);
	y_1_ref=floor(y_1_ref);
	x_2_ref=floor(x_2_ref);
	y_2_ref=floor(y_2_ref);
	x_3_ref=floor(x_3_ref);
	y_3_ref=floor(y_3_ref);
	x_4_ref=floor(x_4_ref);
	y_4_ref=floor(y_4_ref);

    array_to_display=[0 0 0 0 0];
	threshold=5;
	counter = 0; %refresh for each finger
	for i = x_0_ref - 15 : 1 : x_0_ref + 15  
	    for j = y_0_ref - 15 : 1 : y_0_ref + 15
	        if (final_palm(j,i) == 1)
	            counter= counter + 1;
	        end
	    end
	end

	counter
	if counter > threshold   
	    array_to_display(1)=1;
	else
	    array_to_display(1)=0;
	end

	counter = 0; %refresh for each finger
	for i = x_1_ref - 15 : 1 : x_1_ref + 15  
	    for j = y_1_ref - 15 : 1 : y_1_ref + 15
	        if (final_palm(j,i) == 1)
	            counter= counter + 1;
	        end
	    end
	end

	counter
	if counter > threshold   
	    array_to_display(2)=1;
	else
	    array_to_display(2)=0;
	end

	counter = 0; %refresh for each finger
	for i = x_2_ref - 15 : 1 : x_2_ref + 15 
	    for j = y_2_ref - 15 : 1 : y_2_ref + 15
	        if (final_palm(j,i) == 1)
	            counter= counter + 1;
	        end
	    end
	end

	counter
	if counter > threshold   
	    array_to_display(3)=1;
	else
	    array_to_display(3)=0;
	end

	counter = 0; %refresh for each finger
	for i = x_3_ref - 15 : 1 : x_3_ref + 15 
	    for j = y_3_ref - 15 : 1 : y_3_ref + 15
	        if (final_palm(j,i) == 1)
	            counter= counter + 1;
	        end
	    end
	end

	counter
	if counter > threshold   
	    array_to_display(4)=1;
	else
	    array_to_display(4)=0;
	end

	counter = 0; %refresh for each finger
	for i = x_4_ref - 15 : 1 : x_4_ref + 15
	    for j = y_4_ref - 15 : 1 : y_4_ref + 15
	        if (final_palm(j,i) == 1)
	            counter= counter + 1;
	        end
	    end
	end

	counter
	if counter > threshold   
	    array_to_display(5)=1;
	else
	    array_to_display(5)=0;
	end
  array_to_display
end

