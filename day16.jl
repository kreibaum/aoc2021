
## Day 16: Packet Decoder ##
############################

day16_test_1 = "8A004A801A8002F478"
day16_test_2 = "620080001611562C8802118E34"
day16_test_3 = "C0015000016115A2E0802F182340"
day16_test_4 = "A0016C880162017C3686B18A3D4780"
day16_input = readlines(open("input-16"))[1]

function input_to_binary_list(input)
    binary_list = []
    for c in input
        binary = string(parse(Int, c, base = 16), base = 2)
        for _ = length(binary):3
            push!(binary_list, 0)
        end
        for d in binary
            push!(binary_list, parse(Int, d, base = 2))
        end
    end
    binary_list
end

function parse_packet!(input)
    version = grab_int!(input, 3)
    typeid = grab_int!(input, 3)
    if typeid == 4
        content = parse_content!(input)
    else
        length_type_id = grab_int!(input, 1)
        if length_type_id == 0
            # The next 15 bits are the total length of the packet, in bits.
            bits_to_parse = grab_int!(input, 15)
            remaining_data_size = length(input)
            content = []
            while length(input) + bits_to_parse > remaining_data_size
                push!(content, parse_packet!(input))
            end
        else
            # The next 11 bits is the amount of contained packets.
            packets_to_parse = grab_int!(input, 11)
            content = []
            for _ = 1:packets_to_parse
                push!(content, parse_packet!(input))
            end
        end
    end
    (version, typeid, content)
end

function grab_int!(input, digits)::Int
    result = 0
    for _ = 1:digits
        result = result * 2 + popfirst!(input)
    end
    result
end

function parse_content!(input)
    value = 0
    while true
        next_digit = grab_int!(input, 5)
        if next_digit >= 16
            # We can continue, but need to strip of a leading 1
            value = value * 16 + next_digit - 16
        else
            # We've reached the end of the content
            value = value * 16 + next_digit
            break
        end
    end
    value
end

function version_sum(packet)
    version, typeid, content = packet
    if typeid == 4
        version
    else
        sum(version_sum.(content)) + version
    end
end

@assert 16 == version_sum(parse_packet!(input_to_binary_list(day16_test_1)))
@assert 12 == version_sum(parse_packet!(input_to_binary_list(day16_test_2)))
@assert 23 == version_sum(parse_packet!(input_to_binary_list(day16_test_3)))
@assert 31 == version_sum(parse_packet!(input_to_binary_list(day16_test_4)))
@assert 1038 == @show version_sum(parse_packet!(input_to_binary_list(day16_input)))

function package_value(packet)
    version, typeid, content = packet
    if typeid == 0
        sum(package_value.(content))
    elseif typeid == 1
        prod(package_value.(content))
    elseif typeid == 2
        minimum(package_value.(content))
    elseif typeid == 3
        maximum(package_value.(content))
    elseif typeid == 4
        content
    elseif typeid == 5
        @assert length(content) == 2
        package_value(content[1]) > package_value(content[2]) ? 1 : 0
    elseif typeid == 6
        @assert length(content) == 2
        package_value(content[1]) < package_value(content[2]) ? 1 : 0
    elseif typeid == 7
        @assert length(content) == 2
        package_value(content[1]) == package_value(content[2]) ? 1 : 0
    else
        throw("Unknown typeid: $typeid")
    end
end

@assert 3 == package_value(parse_packet!(input_to_binary_list("C200B40A82")))
@assert 54 == package_value(parse_packet!(input_to_binary_list("04005AC33890")))
@assert 7 == package_value(parse_packet!(input_to_binary_list("880086C3E88112")))
@assert 9 == package_value(parse_packet!(input_to_binary_list("CE00C43D881120")))
@assert 1 == package_value(parse_packet!(input_to_binary_list("D8005AC2A8F0")))
@assert 0 == package_value(parse_packet!(input_to_binary_list("F600BC2D8F")))
@assert 0 == package_value(parse_packet!(input_to_binary_list("9C005AC2F8F0")))
@assert 1 == package_value(parse_packet!(input_to_binary_list("9C0141080250320F1802104A08")))

@assert 246761930504 == @show package_value(parse_packet!(input_to_binary_list(day16_input)))